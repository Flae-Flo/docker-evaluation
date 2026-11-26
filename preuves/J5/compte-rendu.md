# J5 — PostgreSQL cloud (Neon)

Date : 26/11/2026. Projet `quiz-app`, branche `production`, base `quiz_db`, PostgreSQL 17, Frankfurt. Schéma initialisé avec `database/init.sql` (3 tables et 2 index).

Connexion par `DATABASE_URL`, alimentée en local par `NEON_DATABASE_URL` via le fichier de surcharge `docker-compose.neon.yml`. URL de connexion avec `sslmode=require` et `channel_binding=require`, conservée dans `.env` ignoré par Git ; aucune URL authentifiée dans `.env.example`. Pour Azure, utiliser une référence à un secret dans la Container App backend.

```powershell
docker compose -f docker-compose.yml -f docker-compose.neon.yml up -d
```

```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
SELECT * FROM quiz_results;
```

Test local connecté à Neon : score 20/20 enregistré. Capture ultérieure : résultats 20/20 et 11/20 toujours visibles. Le test public affiche 16/20 et la capture Neon plus récente montre quatre utilisateurs, mais ne montre pas encore le score 16/20 dans `quiz_results`. Pour corréler précisément le dernier test cloud et prouver la persistance après redéploiement, ajouter une capture de cette requête après recréation/redéploiement :

```sql
SELECT user_id, score, total_questions, completed_at FROM quiz_results ORDER BY completed_at DESC;
```

Commit [741a291](https://github.com/Flae-Flo/docker-evaluation/commit/741a291). Fichiers : [Compose Neon](../../docker-compose.neon.yml), [exemple de variables](../../.env.example).
