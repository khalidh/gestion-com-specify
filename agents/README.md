# Contrat commun des agents

Les définitions Copilot du workspace sont dans `.github/agents/`. Ce dossier contient les contrats structurés partagés par ces agents.

Chaque résultat doit suivre `contracts/agent-result.yaml`: statut, résumé, preuves, hypothèses, erreurs et gate humain. Les agents de ce squelette sont en lecture seule; ils ne lancent ni migration ni écriture dans les sources.