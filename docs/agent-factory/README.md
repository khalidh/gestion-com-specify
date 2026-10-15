# Enterprise Modernization Agent Factory

Guide d'utilisation de la Factory de modernisation. La Factory est un outil d'analyse du dépôt; elle ne remplace pas l'application de gestion commerciale APEX.

## État actuel

Le workflow `reverse-specification` est exécutable en Python en lecture seule. Il analyse une liste fixe de huit sources, produit des brouillons traçables et effectue des contrôles de cohérence avant revue humaine.

Les agents Copilot décrits dans `.github/agents/` sont des contrats de rôle : le CLI ne les invoque pas automatiquement. La proposition de migration reprend des tâches déjà spécifiées; elle ne génère ni code de migration ni changement de base. Le plan de validation reprend les scénarios spécifiés, mais ne les exécute pas. La revue automatique ne vaut pas approbation humaine.

État du pipeline et séquencement : [pipeline.yaml](../../orchestrator/pipeline.yaml). Vue d'ensemble technique : [architecture.md](architecture.md). Étapes et critères du MVP : [mvp-plan.md](mvp-plan.md).

## Démarrage rapide

Prérequis : Python 3.11 ou supérieur et accès en lecture aux fichiers du dépôt.

Depuis la racine du dépôt, dans PowerShell :

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".[test]"
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe -m orchestrator.reverse_specification
```

Le dernier appel affiche le chemin du run créé sous `generated/runs/`. Pour donner un identifiant explicite :

```powershell
.\.venv\Scripts\python.exe -m orchestrator.reverse_specification --run-id run-20261014-demo
```

Chaque identifiant doit être unique. Le workflow refuse les identifiants contenant des séparateurs ou `..`, et refuse d'écraser un dossier existant. Si Python et les dépendances sont déjà installés, les étapes de création d'environnement et d'installation sont facultatives.

## Sources analysées

Le CLI lit exclusivement les huit fichiers définis dans `SOURCE_FILES` dans [reverse_specification.py](../../orchestrator/reverse_specification.py) :

| Source | Usage |
|---|---|
| [spec.md](../../specs/001-gestion-commerciale/spec.md) | Règles métier, références FR/TEST et scénarios de validation spécifiés. |
| [data-model.yaml](../../specs/001-gestion-commerciale/data-model.yaml) | Tables du modèle conceptuel. |
| [plan.md](../../specs/001-gestion-commerciale/plan.md) | Architecture cible déjà proposée et contraintes connues. |
| [tasks.md](../../specs/001-gestion-commerciale/tasks.md) | Tâches existantes réutilisées dans la proposition de migration. |
| [changeset clients](../../database/changelog/changesets/001_gc_customer_foundation.sql) | Tables Oracle effectivement créées par le changeset analysé. |
| [export APEX](../../apex/exports/gestion-commerciale-v1/f100.sql) | Éléments présents dans l'application exportée. |
| [prototype](../../public/app.js) | Données de démonstration du prototype navigateur, jamais assimilées à des faits métier. |
| [contrat ORDS](../../ords/definitions/api-v1.yaml) | Statut documentaire proposé; il ne prouve pas qu'une API est déployée. |

Les chemins `.env*`, `.git`, les journaux, dumps, dépendances et fichiers hors allowlist ne sont pas lus. Modifier l'allowlist est un changement de périmètre qui doit être revu avant exécution.

## Résultats d'un run

Un run crée un nouveau dossier `generated/runs/<run-id>/`. Les sorties restent des brouillons locaux, ignorés par Git. Le workflow actuel produit :

| Fichier | Contenu |
|---|---|
| `inventory.yaml` | Manifeste des sources lues, taille, empreinte SHA-256 et exclusions. |
| `evidence.yaml` | Éléments de preuve avec chemin, localisateur et classification. |
| `business-rules.yaml` | Règles BR extraites; leur présence ne prouve pas leur implémentation. |
| `business-model.yaml` | Entités demandées, tables conceptuelles et état d'implémentation observé. |
| `migration-proposal.yaml` | Groupes de tâches existantes, classés comme proposition uniquement. |
| `target-architecture.md` | Synthèse de l'architecture déjà documentée, contraintes non résolues et gate humain. |
| `validation-plan.yaml` | Scénarios TEST liés aux règles BR; leur statut d'exécution reste `not_run`. |
| `modernization-report.md` | Résumé des écarts, contrôles automatiques et findings de revue. |

Les sorties portent les métadonnées du workflow, du run, de l'heure de création, de l'empreinte du manifeste et du statut d'approbation. Le rapport peut indiquer que les contrôles de cohérence sont réussis tout en restant `incomplete` et en recommandant `block_promotion` : les limites non résolues exigent une décision humaine.

## Sécurité et approbations

- Les sources métier sont en lecture seule; aucun export APEX, fichier SQL, spécification ou donnée source n'est modifié par le CLI.
- Le workflow ne se connecte ni à Oracle ni à ORDS et ne déploie rien.
- Une proposition de migration n'est pas un script et son exécution est désactivée.
- Un plan de validation n'exécute aucun scénario sur une base ou un service.
- Les agents et contrats interdisent les secrets dans les sorties et requièrent des preuves et statuts explicites.
- La promotion d'un artefact vers les spécifications ou la base de connaissances requiert une revue et une approbation humaine.

Les gates du pipeline sont `approve_source_scope`, `review_hypotheses_and_conflicts` et `approve_artifact_promotion`. Pour de futurs tests sur une base ou un service, il faut en plus des données synthétiques approuvées et un environnement isolé. Ne lancez pas de migration ou de test d'écriture sur une base partagée ou de production.

## Rôles des agents

Les définitions détaillées se trouvent dans [.github/agents](../../.github/agents/) et le format de résultat commun dans [agent-result.yaml](../../agents/contracts/agent-result.yaml).

| Agent | Responsabilité |
|---|---|
| Orchestrator | Coordonne les étapes et fait respecter les gates. |
| Discovery | Inventorie les sources, fichiers et dépendances autorisés. |
| Reverse Engineering | Décrit les structures et comportements observables avec preuves. |
| Business Rules | Extrait et relie les règles documentées. |
| Specification | Prépare les spécifications à partir des éléments approuvés. |
| Architecture | Compare et documente frontières, contraintes et options cibles. |
| Migration | Propose des étapes; la génération de code n'est pas activée par ce workflow. |
| Testing | Relie les scénarios et exigences, sans exécuter de tests métier. |
| Review | Identifie les problèmes de traçabilité, sécurité, qualité et cohérence. |
| Knowledge | Prépare la capitalisation après approbation; aucune promotion automatique n'est active. |

Le contrat impose les champs `agent_id`, `status`, `summary`, `evidence`, `assumptions`, `errors` et `human_approval_required`. Les statuts permis sont `complete`, `partial` et `blocked`.

## Extension par technologie

Les adaptateurs sont décrits dans [adapters/README.md](../../adapters/README.md). L'adaptateur APEX reste au stade du contrat. L'adaptateur Oracle Forms vers APEX est bloqué jusqu'à la fourniture et l'autorisation d'un jeu source représentatif (`.fmb`, `.fmx`, bibliothèques ou équivalent). Aucun mapping de conversion n'est présumé. Les adaptateurs SAP et COBOL sont ultérieurs.

Le schéma du modèle métier est [business-model.schema.yaml](../../models/business-model.schema.yaml); il décrit un contrat, pas un modèle généré approuvé. La [base de connaissances](../../knowledge/README.md) ne reçoit que des décisions et résultats revus. Les conventions de conservation des runs figurent dans [generated/README.md](../../generated/README.md).

## Tests et limites connues

Les tests du workflow sont dans [tests/factory](../../tests/factory/). Exécutez-les avec `python -m pytest -q` depuis la racine. Ils couvrent le dépôt réel, les fixtures synthétiques, la traçabilité, les exclusions de secrets, les chemins de sortie et les blocages de revue.

Le workflow est déterministe et adapté au premier terrain APEX du dépôt; il ne constitue pas encore une plateforme d'agents autonome. En particulier :

- les agents Copilot ne sont pas orchestrés par le CLI;
- l'adaptateur APEX n'a pas encore de parseur dédié;
- aucune source Oracle Forms n'est disponible pour valider une conversion;
- la validation fonctionnelle sur Oracle/APEX n'est pas exécutée;
- la revue et la capitalisation finales restent soumises à approbation humaine.

Pour le détail de l'orchestrateur et ses limitations, voir [orchestrator/README.md](../../orchestrator/README.md).