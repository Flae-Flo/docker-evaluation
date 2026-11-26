# J4 — Azure Container Apps

Date : 26/11/2026. Les captures montrent les Container Apps frontend/backend, y compris les variantes standard, et un journal de révisions actives avec l'image du commit. Des erreurs HTTP 404 et 502 ont été rencontrées durant les essais ; un frontend public est ensuite accessible et un quiz public a été effectué. La capture du pipeline final dans [J6](../J6/) montre le job de déploiement réussi.

URL publique visible lors du test : https://quiz.si.jouronlilian.fr/

À compléter : nom des révisions finales, configuration ingress/réseau effective, commande et sortie HTTP 200 de `/health` via le frontend. La capture du quiz ne remplace pas cette preuve spécifique. Cause exacte des erreurs et correction Azure à préciser par le binôme. `/health` ne teste pas PostgreSQL.

Commande de vérification proposée :

```powershell
curl.exe -i https://quiz.si.jouronlilian.fr/health
```

Attendu : HTTP 200 et `{"status":"ok"}` ; résultat à capturer, non vérifié ici.
