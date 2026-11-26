#!/usr/bin/env bash
set -euo pipefail

image_tag=${IMAGE_TAG:-${GITHUB_SHA:?Un tag image est requis}}
registry=$(az acr show -n "$ACR_NAME" -g "$RESOURCE_GROUP" --query loginServer -o tsv)

check_revision() {
  local app=$1 expected_image=$2 revision attempt
  local query="[?properties.active && properties.provisioningState=='Provisioned' && properties.template.containers[0].image=='$expected_image'].name | [0]"

  echo "$app : attente de l'image $expected_image"
  for ((attempt = 1; attempt <= 12; attempt++)); do
    revision=$(az containerapp revision list -n "$app" -g "$RESOURCE_GROUP" \
      --query "$query" --only-show-errors -o tsv)
    if [[ -n "$revision" ]]; then
      echo "$app : revision $revision active et provisionnee avec l'image du commit"
      return 0
    fi
    if ((attempt < 12)); then sleep 5; fi
  done

  echo "::error::$app : aucune revision active et provisionnee pour $expected_image"
  az containerapp revision list -n "$app" -g "$RESOURCE_GROUP" --all --only-show-errors \
    --query '[].{revision:name,image:properties.template.containers[0].image,active:properties.active,provisioning:properties.provisioningState,health:properties.healthState,state:properties.runningState,details:properties.runningStateDetails}' -o table
  return 1
}

check_revision "$BACKEND_APP" "$registry/quiz-backend:$image_tag"
check_revision "$FRONTEND_APP" "$registry/quiz-frontend:$image_tag"
