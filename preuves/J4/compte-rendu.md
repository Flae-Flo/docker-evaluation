# J4 — Azure Container Apps

Le 26 novembre 2026, le [pipeline de déploiement](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45845263076) a mis à jour les deux apps de `quiz-env-standard`. Azure CLI a confirmé les révisions prêtes ci-dessous. Les deux utilisent les [images ACR](../J3/) du commit `ea0b69dd7edccf677b0d0690bb429f6ca21ea62e`.

| Application | Ingress HTTP et port du conteneur | Révision prête |
|---|---|---|
| `quiz-frontend-standard` (NGINX) | Public, `8080` | `quiz-frontend-standard--0000003` |
| `quiz-backend-standard` (Node.js) | Interne, `3007` | `quiz-backend-standard--0000003` |

Le navigateur appelle le frontend. NGINX relaie `/api/` et `/health` vers l’adresse HTTPS interne du backend dans le même environnement. Le backend contacte Neon pour les données du quiz.

Le `404` initial a été reproduit en appelant l’adresse Azure du backend depuis le conteneur frontend. Dans le backend lui-même, `/health` répondait `200` sur le port `3007`. L’environnement Express ne prend pas en charge la découverte interne des services et a rejeté la tentative d’activation de Dapr. Le passage à ACA Standard (profils de charge de travail) a rétabli le routage privé. [Échec du test HTTP](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45820174590) · [Passage à ACA Standard, PR #10](https://github.com/Flae-Flo/docker-evaluation/pull/10)

Test réalisé via l’URL Azure du frontend :

```powershell
curl.exe -sS -w " HTTP %{http_code}\n" https://quiz-frontend-standard.whitepebble-02a3957a.switzerlandnorth.azurecontainerapps.io/health
```

Sortie retranscrite :

```text
{"status":"ok"} HTTP 200
```

Ce test confirme que NGINX atteint le backend. La connexion PostgreSQL est vérifiée séparément dans [J5](../J5/).

Les [captures des Container Apps](2026-11-26-container-apps.png) et du [diagnostic](2026-11-26-revisions-et-diagnostic-404.png) documentent les essais. Un [quiz public terminé](2026-11-26-quiz-termine.png) a été capturé lors du test sur `quiz.si.jouronlilian.fr`.
