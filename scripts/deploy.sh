#!/usr/bin/env bash
set -euo pipefail

# Usage local. Sans option, GitHub Actions fournit deja la configuration.
if [[ ${1:-} == --interactive ]]; then
  ACR_NAME=dockerevaluation
  RESOURCE_GROUP=Docker
  FRONTEND_APP=quiz-frontend-standard
  BACKEND_APP=quiz-backend-standard
  ACA_ENV=quiz-env-standard
  PULL_IDENTITY=quiz-acr-pull

  az login --output none
  az account show --query '{Abonnement:name, ID:id}' -o table

  backend_tags=$(az acr repository show-tags -n "$ACR_NAME" --repository quiz-backend -o tsv)
  frontend_tags=$(az acr repository show-tags -n "$ACR_NAME" --repository quiz-frontend --orderby time_desc -o tsv)
  backend_tags=${backend_tags//$'\r'/}
  frontend_tags=${frontend_tags//$'\r'/}
  IMAGE_TAG=
  while IFS= read -r tag; do
    if [[ "$tag" =~ ^[0-9a-f]{40}$ ]] && grep -Fxq -- "$tag" <<< "$backend_tags"; then
      IMAGE_TAG=$tag
      break
    fi
  done <<< "$frontend_tags"
  if [[ -z "$IMAGE_TAG" ]]; then
    echo "Aucun tag de commit commun aux deux images dans ACR." >&2
    exit 1
  fi

  echo "Images selectionnees : $IMAGE_TAG"
  read -r -p 'Identifiant administrateur du quiz : ' ADMIN_USERNAME
  read -r -p 'Adresse expediteur (ex. onboarding@resend.dev) : ' FROM_EMAIL
  for secret in DATABASE_URL ADMIN_PASSWORD JWT_SECRET RESEND_API_KEY; do
    read -r -s -p "$secret : " "$secret"
    echo
  done
elif (( $# > 0 )); then
  echo "Utilisation : bash scripts/deploy.sh --interactive" >&2
  exit 2
fi

IMAGE_TAG=${IMAGE_TAG:-${GITHUB_SHA:-}}

# Verifier la configuration avant de creer des ressources.
for variable in ACR_NAME RESOURCE_GROUP FRONTEND_APP BACKEND_APP ACA_ENV PULL_IDENTITY IMAGE_TAG DATABASE_URL ADMIN_USERNAME ADMIN_PASSWORD JWT_SECRET RESEND_API_KEY FROM_EMAIL; do
  if [[ -z "${!variable:-}" ]]; then
    echo "Configuration manquante : $variable (voir les secrets GitHub pour les identifiants applicatifs)."
    exit 1
  fi
done

az extension add --name containerapp --upgrade --only-show-errors
REGISTRY=$(az acr show -n "$ACR_NAME" -g "$RESOURCE_GROUP" --query loginServer -o tsv)
LOCATION=$(az acr show -n "$ACR_NAME" -g "$RESOURCE_GROUP" --query location -o tsv)
IDENTITY_ID=$(az identity show -n "$PULL_IDENTITY" -g "$RESOURCE_GROUP" --query id -o tsv)

# 1. Utiliser ACA standard pour la communication privee entre les apps.
ENV_EXISTS=$(az containerapp env list -g "$RESOURCE_GROUP" --query "[?name=='$ACA_ENV'].name" -o tsv)
if [[ -z "$ENV_EXISTS" ]]; then
  az containerapp env create -n "$ACA_ENV" -g "$RESOURCE_GROUP" \
    --location "$LOCATION" --environment-mode WorkloadProfiles --logs-destination none --output none
fi
ENV_MODE=$(az containerapp env show -n "$ACA_ENV" -g "$RESOURCE_GROUP" --query properties.environmentMode -o tsv)
if [[ "${ENV_MODE,,}" == express ]]; then
  echo "$ACA_ENV est en mode Express. Le routage prive exige un environnement ACA standard."
  exit 1
fi

# Les valeurs sensibles sont stockees dans les secrets ACA, sans les afficher.
secrets=("database-url=$DATABASE_URL" "admin-username=$ADMIN_USERNAME"
  "admin-password=$ADMIN_PASSWORD" "jwt-secret=$JWT_SECRET"
  "resend-api-key=$RESEND_API_KEY" "from-email=$FROM_EMAIL")
backend_env=("PORT=3007" "DATABASE_URL=secretref:database-url"
  "ADMIN_USERNAME=secretref:admin-username" "ADMIN_PASSWORD=secretref:admin-password"
  "JWT_SECRET=secretref:jwt-secret" "RESEND_API_KEY=secretref:resend-api-key"
  "FROM_EMAIL=secretref:from-email")

# 2. Deployer le backend avec un ingress interne et une identite ACR en lecture.
BACKEND_EXISTS=$(az containerapp list -g "$RESOURCE_GROUP" --query "[?name=='$BACKEND_APP'].name" -o tsv)
if [[ -z "$BACKEND_EXISTS" ]]; then
  az containerapp create -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
    --environment "$ACA_ENV" --image "$REGISTRY/quiz-backend:$IMAGE_TAG" \
    --user-assigned "$IDENTITY_ID" --registry-identity "$IDENTITY_ID" --registry-server "$REGISTRY" \
    --ingress internal --target-port 3007 --revisions-mode single \
    --cpu 0.25 --memory 0.5Gi --min-replicas 0 --max-replicas 1 \
    --secrets "${secrets[@]}" --env-vars "${backend_env[@]}" --output none
else
  BACKEND_REVISION=$(az containerapp show -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
    --query properties.latestRevisionName -o tsv)
  az containerapp secret set -n "$BACKEND_APP" -g "$RESOURCE_GROUP" --secrets "${secrets[@]}" --output none
  UPDATED_REVISION=$(az containerapp update -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
    --image "$REGISTRY/quiz-backend:$IMAGE_TAG" --set-env-vars "${backend_env[@]}" \
    --query properties.latestRevisionName -o tsv)

  # Une nouvelle revision charge les secrets. Si l'image reste la meme, relancer l'ancienne.
  if [[ -n "$BACKEND_REVISION" && "$UPDATED_REVISION" == "$BACKEND_REVISION" ]]; then
    echo "Redemarrage du backend pour recharger les secrets."
    az containerapp revision restart -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
      --revision "$BACKEND_REVISION" --output none
  fi
fi

# 3. Utiliser l'adresse publiee par l'ingress interne d'Azure.
BACKEND_HOST=$(az containerapp show -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
  --query 'properties.configuration.ingress | (external == `false` && targetPort == `3007`) && fqdn' -o tsv)
if [[ -z "$BACKEND_HOST" || "${BACKEND_HOST,,}" == false ]]; then
  echo "Le backend doit avoir une adresse d'ingress interne sur le port 3007."
  exit 1
fi
FRONTEND_EXISTS=$(az containerapp list -g "$RESOURCE_GROUP" --query "[?name=='$FRONTEND_APP'].name" -o tsv)
if [[ -z "$FRONTEND_EXISTS" ]]; then
  az containerapp create -n "$FRONTEND_APP" -g "$RESOURCE_GROUP" \
    --environment "$ACA_ENV" --image "$REGISTRY/quiz-frontend:$IMAGE_TAG" \
    --user-assigned "$IDENTITY_ID" --registry-identity "$IDENTITY_ID" --registry-server "$REGISTRY" \
    --ingress external --target-port 8080 --revisions-mode single \
    --cpu 0.25 --memory 0.5Gi --min-replicas 0 --max-replicas 1 \
    --env-vars "BACKEND_URL=https://$BACKEND_HOST" --output none
else
  az containerapp update -n "$FRONTEND_APP" -g "$RESOURCE_GROUP" \
    --image "$REGISTRY/quiz-frontend:$IMAGE_TAG" \
    --set-env-vars "BACKEND_URL=https://$BACKEND_HOST" --output none
fi

if [[ ${1:-} == --interactive ]]; then
  FRONTEND_HOST=$(az containerapp show -n "$FRONTEND_APP" -g "$RESOURCE_GROUP" \
    --query properties.configuration.ingress.fqdn -o tsv)
  echo "URL du quiz : https://$FRONTEND_HOST"
fi
