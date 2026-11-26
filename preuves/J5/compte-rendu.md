# J5 — PostgreSQL cloud (Neon)

Date : 26/11/2026. Projet `quiz-app`, branche `production`, base `quiz_db`, PostgreSQL 17, Frankfurt. Le schéma a été initialisé avec [database/init.sql](../../database/init.sql), qui crée trois tables et deux index.

En local, `docker-compose.neon.yml` transmet `NEON_DATABASE_URL` au backend sous le nom `DATABASE_URL`. L’URL de connexion avec `sslmode=require` et `channel_binding=require` est conservée dans le fichier `.env` ignoré par Git. Sur Azure, le workflow lit le secret GitHub `NEON_DATABASE_URL`. Il configure le secret ACA `database-url`, référencé par `DATABASE_URL` dans le backend. [Script de déploiement](../../scripts/deploy.sh)

```powershell
docker compose -f docker-compose.yml -f docker-compose.neon.yml up -d
```

Un test local connecté à Neon a enregistré 20/20. Une [capture ultérieure](2026-11-26-deux-resultats-neon.png) montre les résultats 20/20 et 11/20 toujours présents. [Capture du schéma](2026-11-26-schema-neon.png)

Une requête en lecture seule, exécutée depuis la révision Azure `quiz-backend-standard--0000003` après le [redéploiement sur main](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45845263076), a utilisé la connexion du backend. L’URL et les données des participants n’ont pas été affichées.

```sql
SELECT (SELECT COUNT(*) FROM users) AS utilisateurs,
       COUNT(*) AS resultats,
       COUNT(*) FILTER (WHERE completed_at < TIMESTAMP '2026-11-26 14:43:27')
           AS anterieurs_au_redeploiement,
       EXISTS (SELECT 1 FROM quiz_results WHERE score = 16 AND total_questions = 20)
           AS score_16_sur_20,
       (SELECT COUNT(*) FROM answers) AS reponses
FROM quiz_results;
```

Sortie retranscrite : **8 utilisateurs, 7 résultats et 120 réponses**. Six résultats existaient déjà avant le déploiement du backend précédent (26 novembre 2026 à 14:43:27 UTC). Le score **16/20** est présent en base, ce qui est cohérent avec le [quiz public capturé](../J4/2026-11-26-quiz-termine.png). Ce relevé agrégé ne corrèle pas un identifiant de tentative à la capture.

Sur la même connexion, le client PostgreSQL a confirmé le chiffrement TLS et la vérification du certificat (`tls: true` et `certificat_verifie: true`).

[Commit de la configuration Neon](https://github.com/Flae-Flo/docker-evaluation/commit/741a291) · [Compose Neon](../../docker-compose.neon.yml) · [Exemple de variables](../../.env.example)
