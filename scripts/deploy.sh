#!/usr/bin/env bash
set -euo pipefail

# Verifier la configuration avant de creer des ressources.
for variable in ACR_NAME RESOURCE_GROUP FRONTEND_APP BACKEND_APP ACA_ENV PULL_IDENTITY GITHUB_SHA DATABASE_URL ADMIN_USERNAME ADMIN_PASSWORD JWT_SECRET RESEND_API_KEY FROM_EMAIL; do
  if [[ -z "${!variable:-}" ]]; then
    echo "Configuration manquante : $variable (voir les secrets GitHub pour les identifiants applicatifs)."
    exit 1
  fi
done

az extension add --name containerapp --upgrade --only-show-errors
REGISTRY=$(az acr show -n "$ACR_NAME" -g "$RESOURCE_GROUP" --query loginServer -o tsv)
LOCATION=$(az acr show -n "$ACR_NAME" -g "$RESOURCE_GROUP" --query location -o tsv)
IDENTITY_ID=$(az identity show -n "$PULL_IDENTITY" -g "$RESOURCE_GROUP" --query id -o tsv)

# 1. Creer l'environnement ACA s'il n'existe pas encore.
ENV_EXISTS=$(az containerapp env list -g "$RESOURCE_GROUP" --query "[?name=='$ACA_ENV'].name" -o tsv)
if [[ -z "$ENV_EXISTS" ]]; then
  az containerapp env create -n "$ACA_ENV" -g "$RESOURCE_GROUP" \
    --location "$LOCATION" --logs-destination none --output none
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
    --environment "$ACA_ENV" --image "$REGISTRY/quiz-backend:$GITHUB_SHA" \
    --user-assigned "$IDENTITY_ID" --registry-identity "$IDENTITY_ID" --registry-server "$REGISTRY" \
    --ingress internal --target-port 3007 --revisions-mode single \
    --cpu 0.25 --memory 0.5Gi --min-replicas 0 --max-replicas 1 \
    --secrets "${secrets[@]}" --env-vars "${backend_env[@]}" --output none
else
  az containerapp secret set -n "$BACKEND_APP" -g "$RESOURCE_GROUP" --secrets "${secrets[@]}" --output none
  az containerapp update -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
    --image "$REGISTRY/quiz-backend:$GITHUB_SHA" --set-env-vars "${backend_env[@]}" --output none
fi

# 3. Utiliser l'adresse HTTPS interne du backend dans le meme environnement ACA.
BACKEND_INGRESS_OK=$(az containerapp show -n "$BACKEND_APP" -g "$RESOURCE_GROUP" \
  --query 'properties.configuration.ingress.external == `false` && properties.configuration.ingress.targetPort == `3007`' -o tsv)
if [[ "${BACKEND_INGRESS_OK,,}" != true ]]; then
  echo "Le backend doit avoir un ingress interne sur le port 3007."
  exit 1
fi
ENV_DOMAIN=$(az containerapp env show -n "$ACA_ENV" -g "$RESOURCE_GROUP" \
  --query properties.defaultDomain -o tsv)
test -n "$ENV_DOMAIN" || { echo "Domaine de l'environnement ACA introuvable"; exit 1; }
BACKEND_HOST="$BACKEND_APP.internal.$ENV_DOMAIN"
FRONTEND_EXISTS=$(az containerapp list -g "$RESOURCE_GROUP" --query "[?name=='$FRONTEND_APP'].name" -o tsv)
if [[ -z "$FRONTEND_EXISTS" ]]; then
  az containerapp create -n "$FRONTEND_APP" -g "$RESOURCE_GROUP" \
    --environment "$ACA_ENV" --image "$REGISTRY/quiz-frontend:$GITHUB_SHA" \
    --user-assigned "$IDENTITY_ID" --registry-identity "$IDENTITY_ID" --registry-server "$REGISTRY" \
    --ingress external --target-port 8080 --revisions-mode single \
    --cpu 0.25 --memory 0.5Gi --min-replicas 0 --max-replicas 1 \
    --env-vars "BACKEND_URL=https://$BACKEND_HOST" --output none
else
  az containerapp update -n "$FRONTEND_APP" -g "$RESOURCE_GROUP" \
    --image "$REGISTRY/quiz-frontend:$GITHUB_SHA" \
    --set-env-vars "BACKEND_URL=https://$BACKEND_HOST" --output none
fi
