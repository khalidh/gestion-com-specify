# Changesets Liquibase

Ce répertoire reçoit les changements de schéma et de données relus et approuvés.

## Prototype Clients

`001_gc_customer_foundation.sql` met en place le premier parcours réel : tiers, clients, adresses, contacts, la vue `VW_GC_CUSTOMER_LIST` et `PKG_GC_PARTY`. Il ajoute trois clients de démonstration synthétiques.

Pour le prototype local, ce script a été appliqué avec SQL*Plus dans `ORCLPDB`; son exécution n'a pas été enregistrée dans `DATABASECHANGELOG`. Avant une mise à niveau gérée par Liquibase, initialiser ou synchroniser l'historique dans un environnement isolé pour éviter de réappliquer ces objets.

## Règles

- Un fichier correspond à un changement logique; nom proposé: `NNN_description.sql`.
- Le changelog maître les découvre dans ce répertoire; vérifier l'ordre résultant avec la version Liquibase approuvée avant toute application.
- Un changeset déjà appliqué est immuable. Une correction publiée donne lieu à un nouveau changeset.
- Séparer les modifications de structure, les migrations de données et les données de référence contrôlées.
- Fournir un rollback uniquement s'il est démontré sans perte de données; les changements de données peuvent nécessiter une correction compensatoire.
- Toute modification doit être revue, testée sur une base isolée, liée aux exigences et règles métier concernées, puis approuvée avant déploiement.
- Aucun mot de passe, secret, donnée réelle client ou fournisseur ne doit apparaître dans les fichiers.

## Fondation sécurité et stock proposée

- `001_security_audit.sql` ajoute les métadonnées de comptes et rôles, permissions, MFA par référence externe chiffrée, associations historiques et audit append-only.
- `002_inventory_core.sql` ajoute dépôts, soldes, mouvements, réservations et la vue de disponibilité. Les FK vers `GC_PRODUCT` restent différées jusqu'au changeset catalogue.
- Ces fichiers ne sont pas appliqués à l'instance locale actuelle. Le changeset Clients y a été appliqué hors Liquibase; la validation initiale doit utiliser un `GC_APP` vierge dans un PDB jetable conforme à `tests/database/README.md`.

