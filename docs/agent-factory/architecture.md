# Architecture de l'Agent Factory

## Portée du squelette

Cette Factory est un outil d'analyse et de modernisation ajouté au dépôt existant; elle ne remplace ni ne déplace l'application de gestion commerciale. Les sources métier Oracle/APEX, le prototype Node et les spécifications actuelles sont des entrées en lecture seule.

## Principes

- Python léger pour l'orchestration future; Markdown/YAML pour les contrats et les résultats.
- Agents Copilot spécialisés dans `.github/agents/`; outils minimaux, sans MCP, RAG ou framework agentique lourd à ce stade.
- Contrat de résultat commun dans `agents/contracts/agent-result.yaml`.
- Adaptateurs isolés par technologie; le premier flux exploite les artefacts APEX disponibles. La conversion Forms reste non validée faute de sources Forms.
- Brouillons générés sous `generated/runs/`; toute promotion demande une revue humaine.
- Aucun accès de base de données, déploiement, migration ou mutation automatique des sources.

## Périmètre des agents

Les dix agents déclarés sont Orchestrator, Discovery, Reverse Engineering, Business Rules, Specification, Architecture, Migration, Testing, Review et Knowledge. Leurs entrées, sorties, outils, critères d'arrêt et gates figurent dans leurs fichiers `.agent.md`.

## Limites connues

Le projet Git n'a pas encore de commit ni de remote configuré; la baseline devra être établie séparément avec validation humaine. Les artefacts métier existants mélangent exigences conceptuelles et un sous-ensemble client implémenté; le workflow doit préserver ces statuts. Les sources Forms/SAP/COBOL sont absentes.