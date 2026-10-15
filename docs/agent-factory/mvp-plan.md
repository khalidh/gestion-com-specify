# Plan MVP en cinq étapes

## État au 2026-10-14

- Étapes 1 à 3 : squelette et contrat du modèle en place.
- Étape 4 : première tranche CLI de rétro-spécification implémentée; les agents Copilot ne sont pas encore orchestrés automatiquement.
- Étape 5 : quatre tests pytest sont ajoutés; exécution locale et revue des artefacts restent à valider.

1. **Garde-fous** : figer les racines autorisées, exclusions, format de preuves et politique de lecture seule.
2. **Discovery** : inventorier et lire Markdown, YAML, SQL/PLSQL, exports APEX et contrats ORDS autorisés.
3. **Rétro-spécification** : produire un modèle canonique avec provenance et statuts `specified`, `implemented`, `prototype_demo`, `hypothesis` ou `conflict`.
4. **Écarts** : comparer la spécification au changeset Oracle, à l'export APEX et au prototype; proposer les étapes APEX sans exécuter de migration.
5. **Qualité et approbation** : ajouter pytest pour exclusions, parsing, traçabilité et classification; soumettre les résultats à revue humaine avant promotion.

## Critères d'acceptation du premier workflow

- Aucun accès ni changement de base Oracle, ORDS ou des sources existantes.
- Aucune lecture ou sortie de `.env.local`, autres secrets, journaux ou dumps.
- Chaque entité/règle est liée à une source et classée comme spécifiée, implémentée, démonstrative, proposée, hypothétique ou contradictoire.
- Les hypothèses et données fictives ne deviennent jamais des règles métier implicites.
- Le rapport décrit les écarts observés et les limites de l'analyse; il ne prétend pas convertir Oracle Forms sans source Forms.