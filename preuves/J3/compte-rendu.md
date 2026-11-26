# J3 — Azure CLI et Azure Container Registry

Date : 26/11/2026. Registre `dockerevaluation` : dépôts `quiz-frontend` et `quiz-backend` visibles dans la capture. Le journal de révisions dans [J4](../J4/) montre notamment l'image frontend identifiée par le SHA `c5194b019293d2ffecedefb39cfed6d1f41a51c5`.

À compléter par le binôme : chemin des scripts Azure CLI effectivement utilisés, sortie non sensible de création et liste finale des tags/digests. Les captures ne suffisent pas à prouver la création par CLI.

Commandes de vérification proposées (à exécuter si nécessaire) :

```powershell
az acr repository list --name dockerevaluation -o table
az acr repository show-tags --name dockerevaluation --repository quiz-frontend -o table
az acr repository show-tags --name dockerevaluation --repository quiz-backend -o table
```
