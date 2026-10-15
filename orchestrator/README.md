# Orchestrateur

Le premier workflow déterministe est exécutable en lecture seule :

```powershell
python -m orchestrator.reverse_specification
```

Il lit uniquement les huit chemins allowlistés dans `reverse_specification.py` et crée huit artefacts dans un nouveau dossier sous `generated/runs/`. `target-architecture.md` reprend le plan existant, cite ses sources et signale les versions et gates non résolus; `validation-plan.yaml` relie les scénarios TEST aux règles BR sans les exécuter. Le rapport inclut des contrôles de métadonnées, provenance, traçabilité et gates; il reste incomplet et bloque la promotion tant que les limites documentées ne sont pas levées. Les chemins `.env*`, `.git`, logs, dumps, dépendances et sources non allowlistées ne sont pas lus. Aucun accès Oracle/ORDS, migration ou déploiement n'est effectué.

Le workflow n'invoque pas encore automatiquement les agents Copilot : les définitions `.agent.md` restent des contrats de rôle. Les propositions de migration et le plan de validation sont partiels; ils exigent encore la revue humaine, la définition des préconditions et l'approbation d'un environnement isolé avant toute exécution.

Chaque run porte un identifiant unique; un dossier existant n'est jamais écrasé. Les sorties restent au statut `pending_human_review`.