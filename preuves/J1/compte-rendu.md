# J1 — Conteneurisation locale

Date : 26/11/2026. Validation du formateur confirmée par le groupe.

- Deux Dockerfiles : frontend Node/Vite multi-stage + Nginx, backend Node.js.
- Compose : frontend, backend et PostgreSQL 17 Alpine, réseau bridge `quiz-network`, volume nommé `postgres-data`, initialisation par `database/init.sql`.
- Build réussi, API `/health` renvoyant `status: ok`, trois tables créées, quiz et administration fonctionnels.
- Avant/après `docker compose down` puis `docker compose up -d` : résultat ID 1, score 15/20 et date identiques. Le volume n'a pas été supprimé. Les 20 réponses ont été comptées avant recréation.

## Commandes et fichiers

```powershell
docker compose config --quiet
docker compose up -d --build
docker compose ps
Invoke-RestMethod http://localhost:8087/health
docker compose exec db psql -U quiz_user -d quiz_db -c "\dt"
docker compose exec db psql -U quiz_user -d quiz_db -c "SELECT * FROM quiz_results;"
docker compose down
docker compose up -d
docker compose exec db psql -U quiz_user -d quiz_db -c "SELECT * FROM quiz_results;"
```

Fichiers : [Dockerfile](../../Dockerfile), [backend/Dockerfile](../../backend/Dockerfile), [Compose](../../docker-compose.yml), [SQL](../../database/init.sql).
Commit initial : [52be503](https://github.com/Flae-Flo/docker-evaluation/commit/52be503).
