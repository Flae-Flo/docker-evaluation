#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP=Docker
apps=(quiz-frontend-standard quiz-backend-standard)

az login --output none
az account show --query '{Abonnement:name, ID:id}' -o table
echo "Applications a supprimer dans $RESOURCE_GROUP : ${apps[*]}"
read -r -p 'Saisis SUPPRIMER pour confirmer : ' confirmation
if [[ "$confirmation" != SUPPRIMER ]]; then
  echo "Suppression annulee."
  exit 0
fi

for app in "${apps[@]}"; do
  app_id=$(az containerapp list -g "$RESOURCE_GROUP" --query "[?name=='$app'].id | [0]" -o tsv)
  if [[ -n "$app_id" ]]; then
    az containerapp delete -n "$app" -g "$RESOURCE_GROUP" --yes --output none
    echo "$app supprimee."
  else
    echo "$app deja absente."
  fi
done
