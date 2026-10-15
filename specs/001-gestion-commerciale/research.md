# Recherche et décisions techniques

**Fonctionnalité**: Gestion commerciale pour PME  
**Date**: 2026-10-12

## Faits établis

- La constitution impose Oracle Database, Oracle APEX, PL/SQL, ORDS, utPLSQL, Playwright, modularité et documentation française.
- Les clarifications fixent la France, l'euro uniquement, une seule entité juridique, les comptes locaux et le MFA pour administrateurs/approbateurs.
- La spécification fixe une cible de 50 utilisateurs simultanés, 50 000 fiches de référence et les temps p95 des recherches et validations.
- Le dépôt ne contient aucun code applicatif, schéma Oracle, pipeline CI/CD, version Oracle/APEX/ORDS ou outil de migration existant.

## Décisions de conception

### Monolithe modulaire Oracle

**Décision**: un seul produit applicatif et une seule base Oracle, avec frontières logiques par domaine et packages PL/SQL explicites.  
**Raison**: le périmètre vise une PME et une entité; les opérations commande/crédit/stock/facture exigent des transactions cohérentes.  
**Alternatives**: microservices ou schéma Oracle par module. Écartés en v1 car ils ajoutent des déploiements, des transactions distribuées et des grants inter-schémas sans exigence multi-entité ou d'isolation réglementaire identifiée.

### Frontières des responsabilités

**Décision**: les packages métier possèdent validations, calculs, transitions et mutations; APEX appelle les packages et lit des vues autorisées; ORDS transforme les contrats JSON en appels aux mêmes packages. Aucun client ne reçoit un droit DML direct sur les tables métier.  
**Raison**: une seule implémentation des BR-001 à BR-050 prévient les écarts entre écrans, API et traitements.

### Transactions et concurrence

**Décision**: les packages ne valident ni n'annulent leur transaction. Une action métier complète est atomique à la frontière de la requête APEX/ORDS. La confirmation de commande verrouille de façon cohérente le crédit du client et les stocks produit/dépôt avant de calculer et réserver. Les mouvements de stock et les allocations financières sont conservés comme écritures traçables.  
**Raison**: une réservation concurrente ou un double clic ne doit pas dépasser le plafond, le stock ou le solde d'une facture.  
**Alternative**: calcul optimiste seul. Écarté comme contrôle unique pour les invariants financiers et de stock; un numéro de version reste utile pour détecter les modifications périmées dans l'interface.

### Modèle relationnel

**Décision**: modèle normalisé autour des tiers, produits, documents et écritures; clés étrangères, contraintes d'unicité et de domaine pour les invariants locaux; packages transactionnels pour les règles inter-lignes, plages tarifaires et transitions. Les lignes de documents conservent les valeurs historiques utiles (désignation, unité, prix, remise et taxe) pour garantir l'immuabilité comptable sans relire un catalogue modifié.

### Scripts et déploiement de schéma

**Décision proposée**: Liquibase avec changesets SQL source dans Git, identifiant et ordre explicites, changelog maître et historique de déploiement. Les corrections de schéma sont forward-only par défaut; un rollback n'est fourni que s'il est démontré sans perte de données. Les scripts de référence et fixtures de test sont séparés des migrations de production.  
**Raison**: l'historique, l'ordre, la détection d'une migration déjà appliquée et la revue Git sont nécessaires pour des versions reproductibles.  
**Alternatives**: scripts SQL ad hoc lancés manuellement ou SQLcl seul. Écartés comme mécanisme principal car ils ne fournissent pas seuls un historique de changelog standard. Le choix Liquibase reste à approuver avec l'équipe DBA avant création des scripts.

### Tests

**Décision**: utPLSQL couvre chaque package, ses validations et ses transactions; Playwright couvre les parcours APEX et les contrats HTTP ORDS; des scénarios multi-session testent les verrous du crédit et du stock. Chaque FR/NFR est reliée à une ou plusieurs BR et à un test ou moyen de vérification. Les 50 BR doivent toutes être couvertes avant une release.

### Versions et environnement

**Décision**: ne pas inventer de versions. L'inventaire de l'environnement choisira un ensemble Oracle Database/APEX/ORDS/Liquibase/utPLSQL/Node/Playwright compatible et supporté par l'entreprise. Le design reste limité aux fonctions relationnelles, packages, transactions, APEX et ORDS disponibles dans la cible sélectionnée.  
**Gate**: la matrice exacte de versions et la chaîne CI/CD sont approuvées avant les migrations ou exports APEX de production.

### Conformité française et facturation électronique

**Décision**: les documents et séries restent conçus pour intégrer les mentions, événements et échanges exigés en France. Le périmètre de réception/émission électronique et le recours à une plateforme conforme doivent être établis par le responsable comptable à partir des règles officielles applicables à la date de mise en service. La présente recherche n'a pas confirmé de calendrier ou de détail réglementaire; aucun délai légal n'est affirmé ici.  
**Gate**: pas de mise en service de facturation avant validation écrite des obligations applicables, du parcours de transmission et de l'archivage.

## Points à confirmer avant réalisation

- Versions, édition Oracle, hébergement, disponibilité des environnements et outil CI/CD.
- Compatibilité et mode d'activation du MFA dans les versions APEX/ORDS sélectionnées; méthode de facteur et récupération de compte.
- Obligations françaises de facturation électronique et canal accepté, après revue comptable/juridique.
- Valeurs métier des seuils d'approbation, de crédit, de remise et des tolérances de rapprochement.
- Confirmation des objectifs de sauvegarde/restauration et des navigateurs supportés.

Ces points sont des gates d'exploitation ou de validation avant développement, pas des marqueurs de clarification fonctionnelle ouverts dans la spécification.