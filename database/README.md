# Conventions Oracle et PL/SQL

Ce document définit les conventions proposées pour les changements Oracle. Les versions de Database, APEX, ORDS et Liquibase restent à approuver avec l'équipe DBA avant application de tout changeset.

## Nommage

- Préfixe de schéma fonctionnel: `GC_`; tables et vues en majuscules avec noms explicites.
- Packages métier: `PKG_GC_<DOMAINE>`; séparer spécification et corps en fichiers `.pks.sql` et `.pkb.sql`.
- Contraintes: préfixes `PK_`, `FK_`, `UK_` et `CK_`; noms concis, uniques et associés à la table concernée.
- Index: préfixe `IX_`, colonnes et ordre alignés sur une requête ou jointure mesurée.
- Les identifiants des règles métier `BR-NNN` et des exigences ne sont jamais réutilisés.

## Changements et compilation

- Les changesets sont versionnés sous `database/changelog/changesets/` et inclus par `db.changelog-master.yaml`.
- Un changeset publié n'est pas modifié; toute évolution utilise un nouveau changeset relu par un pair.
- Documenter dépendances, impact sur les données et stratégie compensatoire/rollback avant revue.
- Compiler les spécifications avant les corps de packages; compiler les dépendances communes avant les modules consommateurs.
- Les packages métier ne réalisent pas de `COMMIT` ou `ROLLBACK` internes: la transaction appartient à la frontière d'action APEX/ORDS. Exception limitée: `PKG_GC_AUDIT.WRITE_SECURITY_EVENT` utilise une transaction autonome afin qu'un refus d'accès reste auditable après le rollback de la requête; les événements des opérations métier réussies restent dans leur transaction.
- Aucun accès de mutation direct aux tables n'est accordé à APEX ou ORDS; les mutations passent par les packages métier.
- Indexer selon les plans d'exécution et les mesures NFR; ne pas créer d'index non justifié.

## Qualité et sécurité

- Toute règle métier doit être référencée par un test utPLSQL et, pour un parcours visible, par un test Playwright.
- Les opérations sensibles écrivent leur audit dans la même transaction métier lorsque l'opération réussit.
- Utiliser uniquement des données synthétiques dans les fixtures; aucun secret ne doit être versionné.
- L'identité APEX est dérivée du contexte de session authentifié; l'absence d'identité ou de permission entraîne un refus. Le raccordement d'une identité ORDS doit être validé avant d'ouvrir des ressources.
- N'appliquer aucun script avant approbation de la spécification, choix des versions et validation de l'environnement isolé.
