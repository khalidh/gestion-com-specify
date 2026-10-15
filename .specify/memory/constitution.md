<!--
Sync Impact Report
Version change: scaffold non versionné -> 1.0.0 (adoption initiale)
Modified principles: aucun principe existant; cinq principes initiaux définis
Added sections: Contraintes techniques et securite; Workflow de specification et qualite
Removed sections: aucune
Follow-up TODO: confirmer la date historique de ratification
-->

# Constitution du projet de gestion commerciale

## Principes fondamentaux

### I. Architecture modulaire
Le système MUST être organisé en modules métier à responsabilités explicites et interfaces documentées. Les dépendances entre modules MUST rester dirigées et limitées; tout partage de données ou de contrat entre modules MUST être explicite et testé. Cette organisation permet de faire évoluer les domaines sans couplage accidentel.

### II. Logique metier centralisee et presentation separee
Les règles métier MUST être implémentées dans des packages PL/SQL, qui constituent la source faisant autorité pour les validations et les transitions métier. Oracle APEX MUST présenter et orchestrer les interactions sans dupliquer ces règles dans ses pages, composants ou processus. Les contrats REST ORDS MUST déléguer le traitement métier aux packages et ne MUST contenir aucune règle concurrente.

### III. Oracle APEX et API REST ORDS
L'interface utilisateur MUST être réalisée avec Oracle APEX et les API REST MUST être exposées avec ORDS. Les contrats d'API, leurs erreurs, leurs autorisations et leur compatibilité MUST être documentés et testés. Toute interface, interne ou externe, MUST passer par un contrat explicite plutôt que par un accès non maîtrisé aux objets d'un autre module.

### IV. Tests automatises et traçabilite
Les packages PL/SQL MUST être vérifiés par des tests automatisés utPLSQL et les parcours d'interface MUST être vérifiés par Playwright. Chaque exigence MUST être reliée aux règles métier applicables, identifiées de manière stable (BR-001, BR-002, etc.), et aux tests qui la couvrent. Une modification MUST mettre à jour cette chaîne de traçabilité et les tests affectés avant approbation.

### V. Securite, audit et responsabilite
L'accès MUST être contrôlé selon des rôles et le moindre privilège, côté APEX comme côté API et base de données. Les opérations métier sensibles MUST être auditées avec l'acteur, l'horodatage, l'action et la référence de l'objet concerné; les données d'audit MUST être protégées contre les modifications non autorisées. Les contrôles d'autorisation et les traces d'audit MUST être couverts par des tests.

## Contraintes techniques et securite

- Oracle Database MUST être le système de gestion des données et Oracle APEX la plateforme de l'interface.
- ORDS MUST exposer les API REST; les packages PL/SQL MUST porter les opérations métier et les contrôles transactionnels.
- Les données MUST être gérées avec des contraintes et des transactions cohérentes avec les invariants métier. Les accès aux données MUST respecter les frontières des modules.
- Toute règle métier MUST recevoir un identifiant stable au format BR-NNN, par exemple BR-001. Les identifiants existants MUST être conservés lors des évolutions; une règle supprimée ne MUST pas voir son identifiant réutilisé.
- La documentation, les spécifications, les messages fonctionnels et les procédures du projet MUST être rédigés en français. Les identifiants techniques peuvent suivre les conventions Oracle et les contraintes des outils.
- Les secrets MUST être exclus du dépôt et des journaux. Les données sensibles MUST être limitées aux besoins autorisés et protégées dans les environnements de test.

## Workflow de specification et qualite

- Aucune implémentation, migration de schéma ou exposition d'API MUST commencer avant la validation explicite des spécifications concernées.
- Les spécifications MUST décrire les besoins, critères d'acceptation, règles BR, rôles, données, erreurs et exigences d'audit applicables.
- Avant validation, les ambiguïtés MUST être résolues avec les parties prenantes. Après validation, tout changement de portée MUST être documenté et approuvé avant sa mise en œuvre.
- Les tests utPLSQL et Playwright MUST être automatisables et exécutés dans le contrôle qualité adapté. Une livraison MUST échouer si les tests obligatoires échouent ou si une exigence n'a pas de couverture tracée.
- Les revues MUST vérifier la conformité à cette constitution, la séparation entre métier et présentation, les contrôles de sécurité, l'audit et la mise à jour de la documentation en français.

## Gouvernance

Cette constitution est la référence obligatoire pour les spécifications, la conception, le développement, les tests et les revues du projet. Une exception MUST être motivée, documentée, limitée dans le temps et approuvée par les responsables du projet avant son application.

Toute modification de la constitution MUST être revue et approuvée par les responsables du projet. Elle MUST inclure sa justification, son impact sur les spécifications, les règles BR, les tests et les pratiques existantes. Les versions suivent le versionnage sémantique: MAJOR pour une modification incompatible des obligations, MINOR pour l'ajout ou l'élargissement substantiel d'une obligation, PATCH pour une clarification sans changement de sens.

Chaque spécification et chaque revue de livraison MUST vérifier la conformité aux principes applicables et la chaîne de traçabilité exigences-règles-tests. Les écarts MUST être consignés avec leur résolution ou leur exception approuvée. La constitution prévaut sur toute pratique locale contradictoire.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): date historique à confirmer | **Last Amended**: 2026-10-12
