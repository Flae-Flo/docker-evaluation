# Preuves de validation — Quiz App

Date : 26 novembre 2026. Captures et comptes rendus classés conformément aux consignes. Les captures retenues sont recadrées ou masquées lorsque nécessaire ; aucun fichier `.env`, secret Azure ou URL PostgreSQL authentifiée n'est inclus. Les extraits de terminal sont identifiés comme retranscriptions.

| Jalon | Dossier | État des preuves |
|---|---|---|
| J1 | [Conteneurisation](J1/) | Tests et persistance ; validation confirmée par le groupe |
| J2 | [Sécurité](J2/) | Six scans et tests de durcissement |
| J3 | [ACR](J3/) | Registre, deux images, tag commun et digests vérifiés ; scripts Azure CLI |
| J4 | [Container Apps](J4/) | Révisions, réseau privé et HTTP 200 via NGINX vérifiés |
| J5 | [Neon](J5/) | Connexion TLS et résultats conservés après redéploiement vérifiés |
| J6 | [CI/CD](J6/) | Builds et scans Trivy sur PR, déploiement automatique et opérations manuelles |

[Dépôt GitHub](https://github.com/Flae-Flo/docker-evaluation)
