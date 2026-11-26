# J2 — Sécurisation et scans Trivy

Date : 26/11/2026. Tests techniques réussis ; validation formateur à confirmer.

| Image | LOW | MEDIUM | HIGH | CRITICAL | Total |
|---|---:|---:|---:|---:|---:|
| Frontend initial | 0 | 4 | 0 | 0 | 4 |
| Frontend secure | 48 | 13 | 13 | 1 | 75 |
| Frontend secure-v2 | 0 | 0 | 0 | 0 | 0 |
| Backend initial | 5 | 21 | 10 | 0 | 36 |
| Backend secure | 5 | 21 | 10 | 0 | 36 |
| Backend secure-v2 | 1 | 14 | 10 | 0 | 25 |

Mesures : utilisateurs non-root (101/nginx, 1000/node), `cap_drop: ALL`, `no-new-privileges`, limites CPU/RAM, backend en lecture seule avec `/tmp` en tmpfs. Passage Nginx au port 8080 ; mise à jour Alpine via `apk upgrade --no-cache` après détection d'une CVE critique. Les 25 détections résiduelles du backend concernent npm global ; aucune CRITICAL détectée dans les deux images finales lors de ces scans. Les HIGH restent à traiter : le non-root réduit certains impacts, sans supprimer les vulnérabilités. Prévoir mise à jour ou suppression des outils inutiles et nouveau scan.

Trivy : échecs Google/GitHub/Docker Hub ; téléchargement réussi via AWS ECR et cache nommé.

```powershell
docker run --rm -e GODEBUG=http2client=0 -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --download-db-only --timeout 3m --db-repository public.ecr.aws/aquasecurity/trivy-db:2
docker compose build --pull --no-cache
docker compose up -d
docker compose exec frontend id
docker compose exec backend id
Invoke-RestMethod http://localhost:8087/health
$images = @("quiz-frontend:initial", "quiz-backend:initial", "quiz-frontend:secure", "quiz-backend:secure", "quiz-frontend:secure-v2", "quiz-backend:secure-v2")
foreach ($image in $images) {
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --skip-db-update --scanners vuln --timeout 5m $image
}
```

Les six rapports dans `rapports/` proviennent des scans réalisés (encodage texte normalisé). Commit : [4d0e36b](https://github.com/Flae-Flo/docker-evaluation/commit/4d0e36b).
