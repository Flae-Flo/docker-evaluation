# J3 — Azure CLI et Azure Container Registry

Le 26 novembre 2026, Azure CLI a confirmé le registre `dockerevaluation` (SKU Standard, Switzerland North) et les deux dépôts `quiz-frontend` et `quiz-backend`. La [capture des dépôts](2026-11-26-depots-acr.png) montre leur présence dans ACR.

Les deux images portent le tag du commit `ea0b69dd7edccf677b0d0690bb429f6ca21ea62e`, issu de la [fusion de la PR #14](https://github.com/Flae-Flo/docker-evaluation/pull/14). Le [run de publication](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45845263076) et les [révisions ACA](../J4/) utilisent ce même tag.

| Dépôt | Digest relevé dans ACR |
|---|---|
| `quiz-frontend` | `sha256:4c90f22732d67973092cc1bfbb2682c115680d0c2ef20faa5e81aa9738f24477` |
| `quiz-backend` | `sha256:d5f843bf0d55e53f839da054eafda31a5efcd3303a5b06be42b6fd099227daa9` |

Commandes de vérification du registre et des images :

```bash
tag=ea0b69dd7edccf677b0d0690bb429f6ca21ea62e
az acr show -n dockerevaluation -g Docker --query '{nom:name,region:location,sku:sku.name,serveur:loginServer}'
az acr repository show -n dockerevaluation --image "quiz-frontend:$tag" --query digest -o tsv
az acr repository show -n dockerevaluation --image "quiz-backend:$tag" --query digest -o tsv
```

GitHub Actions se connecte à Azure par OIDC et publie via `docker push` après le scan. L’identité du pipeline dispose de `AcrPush` et peut lire les propriétés du registre nécessaires à `az acr show`. Les Container Apps utilisent `quiz-acr-pull` pour télécharger les images. [Workflow de publication](../../.github/workflows/acr.yml)

Le pipeline a utilisé [deploy.sh](../../scripts/deploy.sh) pour provisionner et mettre à jour les Container Apps par Azure CLI. Le mode interactif et [destroy.sh](../../scripts/destroy.sh) sont documentés dans le [README](../../README.md#déploiement-et-nettoyage-depuis-un-terminal).
