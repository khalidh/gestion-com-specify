# Workflow de rétro-spécification

Le contrat d'ensemble est défini dans `orchestrator/pipeline.yaml`. La première tranche déterministe est lancée avec `python -m orchestrator.reverse_specification`.

Elle génère l'inventaire, les preuves, les 50 règles source, le modèle de CLIENT/PRODUIT/COMMANDE/FACTURE, une proposition basée sur les tâches existantes et un rapport d'écarts. Les sorties sont des brouillons sous `generated/runs/`; la génération n'implique ni approbation ni exécution de migration.