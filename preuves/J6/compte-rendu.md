# J6 — CI/CD

Date : 26/11/2026.

## J6-A — Intégration continue

Le [workflow acr.yml](../../.github/workflows/acr.yml) construit les deux images sur les PR vers `main`. Chaque job lance Trivy sur l’image construite, avec `severity: CRITICAL`, `exit-code: '1'` et `ignore-unfixed: false`. Un scan qui échoue arrête son job. Les rapports locaux avant et après durcissement sont dans [J2](../J2/rapports/).

- [PR #5, publication ACR](https://github.com/Flae-Flo/docker-evaluation/pull/5) · [run CI](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45806888198). Les jobs frontend et backend passent.
- [PR #10, routage ACA Standard](https://github.com/Flae-Flo/docker-evaluation/pull/10) · [run CI](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45822345672). Les deux jobs images passent et le déploiement est ignoré sur la PR.

## J6-B — Déploiement continu

Un push sur `main` après fusion déclenche la construction et le scan. Chaque job publie l’image qu’il a scannée sous le SHA du commit. Le job de déploiement attend la publication des deux images, met à jour les Container Apps, vérifie les révisions et teste `/health` via le frontend.

- [Run réussi après la PR #10](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45822525195) : premier déploiement réussi dans l’environnement Standard.
- [Run réussi après la PR #14](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45845263076) : commit de fusion `ea0b69dd7edccf677b0d0690bb429f6ca21ea62e`, deux jobs images et job ACA réussis. [Digests ACR](../J3/) · [Révisions et test HTTP](../J4/)
- [Suppression manuelle réussie](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45829395739) · [Recréation manuelle réussie](https://github.com/Flae-Flo/docker-evaluation/actions/runs/45829692358). Ces workflows ciblent les deux applications Standard et conservent le registre et Neon.

Captures existantes : [jobs images](2026-11-26-jobs-images.png) et [déploiement réussi](2026-11-26-pipeline-deploiement-reussi.png).
