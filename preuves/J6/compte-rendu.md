# J6 — CI/CD

Date : 26/11/2026.

## J6-A — Intégration continue

Le workflow fourni dans l'archive intermédiaire configure le build en matrice frontend/backend et Trivy (`severity: CRITICAL`, `exit-code: '1'`, `ignore-unfixed: false`) sur PR vers `main`. Les rapports locaux sont dans [J2](../J2/rapports/). La capture des jobs images montre leur réussite, mais ne suffit pas à identifier une PR, le contrôle requis et l'approbation. À joindre : lien exact de la PR, capture des checks requis et approbation avant fusion, lien du run CI.

## J6-B — Déploiement continu

Le screenshot `azure.png` renommé dans ce dossier montre le workflow `acr.yml` sur push : les deux jobs images et « Déployer dans ACA » sont verts. Les dépôts ACR sont visibles dans [J3](../J3/) et les révisions dans [J4](../J4/). Le lien exact du run final, son commit et la preuve de déclenchement après fusion dans `main` restent à ajouter.

- [Pull Requests du dépôt](https://github.com/Flae-Flo/docker-evaluation/pulls)
- [GitHub Actions](https://github.com/Flae-Flo/docker-evaluation/actions)
- [Workflow du dépôt](../../.github/workflows/acr.yml)

Ces liens généraux ne remplacent pas les liens des PR et runs spécifiques demandés.
