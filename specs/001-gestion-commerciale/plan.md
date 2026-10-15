# Implementation Plan: Gestion commerciale pour PME

**Branch**: `001-gestion-commerciale` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

**Input**: Architecture Oracle imposée par la demande `/speckit.plan` et spécification clarifiée.

## Summary

Concevoir une application de gestion commerciale pour une PME française, pour une seule entité juridique et en EUR. L'architecture est un monolithe modulaire sur Oracle Database: les packages PL/SQL sont l'unique autorité métier, Oracle APEX porte les écrans, ORDS expose les contrats REST, les changements de schéma sont versionnés dans Git, utPLSQL teste les services et Playwright valide les parcours navigateur et API.

Ce document et ses annexes sont des livrables de conception uniquement. La spécification a été approuvée le 2026-10-12 (T001). Aucun développement, script de migration ni déploiement ne peut commencer avant la levée des gates techniques, réglementaires et opérationnels restants listés ci-dessous.

## Technical Context

**Language/Version**: SQL et PL/SQL sur la version Oracle cible; TypeScript pour les tests Playwright. Les versions précises ne sont pas présentes dans le dépôt et seront fixées après inventaire de l'environnement cible.

**Primary Dependencies**: Oracle Database, Oracle APEX, ORDS, utPLSQL, Playwright Test et Liquibase avec changesets SQL versionnés.

**Storage**: Tables relationnelles Oracle normalisées; contraintes, index et packages propriétaires de l'application. EUR et une entité juridique en v1.

**Testing**: utPLSQL pour logique et transactions PL/SQL; Playwright pour parcours APEX et contrats REST; tests de migration et scénarios de concurrence avant livraison.

**Target Platform**: Environnement Oracle hébergé par l'entreprise, accessible par navigateur de bureau; topologie et versions exactes à confirmer avant implémentation.

**Project Type**: Application web Oracle APEX avec API REST ORDS et services métier PL/SQL, organisée en modules dans un monolithe modulaire.

**Performance Goals**: NFR-001: 50 utilisateurs simultanés; jusqu'à 50 000 fiches clients/produits; p95 <2 s pour une recherche et <3 s pour une validation documentaire.

**Constraints**: France, EUR, entité unique, comptes locaux, MFA obligatoire pour administrateurs et approbateurs; documents conformes aux règles françaises applicables; aucune logique métier dans APEX/ORDS; aucun développement avant approbation de la spécification.

**Scale/Scope**: PME, une entité juridique, plusieurs dépôts, 8 parcours prioritaires et 50 règles BR; version Oracle/APEX/ORDS et matrice de navigateurs à inventorier.

## Constitution Check

*Gate: vérifié avant la recherche et à nouveau après la conception.*

- **Architecture modulaire**: PASS — modules de domaine et interfaces PL/SQL/REST explicitement séparés.
- **Métier distinct de la présentation**: PASS — packages PL/SQL seuls propriétaires des validations et transitions; APEX présente/orchestre, ORDS adapte les contrats.
- **Technologies imposées**: PASS — Oracle Database, APEX, ORDS et scripts SQL versionnés dans Git.
- **Qualité et traçabilité**: PASS — utPLSQL, Playwright et liens FR/NFR → BR → TEST conservés dans la spécification.
- **Sécurité et audit**: PASS — comptes individuels, rôles, MFA privilégié, journal d'audit protégé et tests de refus.
- **Documentation française**: PASS — tous les nouveaux documents du projet sont rédigés en français; identifiants techniques Oracle conservés.
- **Validation préalable**: approbation formelle enregistrée le 2026-10-12; le gate d'implémentation reste BLOQUÉ jusqu'à la validation des versions cibles, des obligations françaises et des autres prérequis d'exploitation.
- **Écarts à la constitution**: aucun.

## Project Structure

### Documentation (this feature)

```text
specs/001-gestion-commerciale/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── ui-screens.md
├── quickstart.md
├── contracts/
│   └── rest-api.md
├── checklists/
│   └── requirements.md
└── tasks.md              # créé ultérieurement par /speckit-tasks
```

### Source Code (repository root)

```text
database/
├── changelog/
│   ├── db.changelog-master.yaml
│   └── changesets/              # changesets SQL Liquibase versionnés dans Git
├── reference-data/              # référentiels non sensibles, contrôlés
└── test-fixtures/                # données synthétiques uniquement
apex/
└── exports/                     # exports APEX séparés par application/version
ords/
└── definitions/                 # contrats et définitions ORDS versionnés
tests/
├── utplsql/                      # suites par package et module
└── playwright/                   # parcours navigateur et API
specs/                            # spécifications et décisions approuvées
```

**Structure Decision**: Un dépôt unique pour le monolithe modulaire. Les changesets SQL, exports APEX, définitions ORDS, tests et documentation évoluent ensemble dans Git. Les chemins sont une cible de conception; ils ne sont pas encore créés et ne constituent pas des scripts de déploiement.

## Architecture proposée

### Modules et packages métier

Chaque module expose une interface publique PL/SQL stable et garde ses tables et règles internes derrière cette interface. Les accès APEX en lecture passent par des vues métier autorisées; toute mutation passe par un package. ORDS ne contient que la validation de forme du contrat, la conversion JSON et l'appel au package concerné.

| Module | Packages proposés | Responsabilité |
|---|---|---|
| Référentiels | `PKG_GC_PARTY`, `PKG_GC_CATALOG` | Tiers, adresses, contacts, produits et statuts. |
| Tarification et fiscalité | `PKG_GC_PRICING`, `PKG_GC_TAX` | Tarifs, validité, remises, taxes et calculs documentaires. |
| Ventes | `PKG_GC_QUOTES`, `PKG_GC_SALES_ORDERS` | Devis, conversion, crédit, confirmation et annulation des commandes. |
| Achats | `PKG_GC_PROCUREMENT` | Commandes d'achat, approbations, réceptions et rapprochements fournisseurs. |
| Stocks et logistique | `PKG_GC_INVENTORY`, `PKG_GC_DELIVERY` | Disponibilité, réservation, mouvements, transferts et livraisons. |
| Facturation et règlements | `PKG_GC_BILLING`, `PKG_GC_PAYMENTS` | Factures, avoirs, échéances, paiements et affectations. |
| Sécurité et audit | `PKG_GC_SECURITY`, `PKG_GC_AUDIT` | Comptes locaux, rôles, MFA privilégié, contrôles et audit. |
| Pilotage | `PKG_GC_REPORTING` | Agrégats de lecture dérivés de documents validés. |

Les packages sont organisés par domaine, sans dépendances cycliques. Les orchestrateurs (confirmation d'une commande, validation d'une facture, confirmation d'une expédition) peuvent appeler plusieurs modules dans une même transaction. Les packages métier ne font jamais de `COMMIT` ou `ROLLBACK` internes.

### Transactions et concurrence

La transaction correspond à une commande utilisateur complète reçue par APEX ou ORDS. Le point d'entrée valide les permissions puis appelle les packages; la réussite valide l'ensemble, une erreur annule l'ensemble. Une validation de facture, un mouvement de stock, ses allocations et son événement d'audit métier restent atomiques.

| Opération | Unité atomique | Contrôle de concurrence |
|---|---|---|
| Confirmation commande client | Contrôle de crédit + réservations + état de commande + audit métier. | Verrouiller le client puis les soldes produit/dépôt dans un ordre stable; recalculer l'exposition et le disponible sous verrou. |
| Réception achat | Lignes acceptées + mouvements entrants + reliquat commande + audit. | Verrouiller les lignes de commande et les soldes des dépôts touchés; empêcher une double réception. |
| Expédition livraison | État livraison + diminution des réservations et quantités physiques + mouvements. | Verrouiller les réservations puis les soldes produit/dépôt; confirmer une seule fois. |
| Validation facture | Contrôles fiscaux + attribution de référence + gel du document + audit. | Sérialiser l'attribution de la référence; interdire les changements de lignes après validation. |
| Affectation règlement | Affectations + recalcul des soldes + audit. | Verrouiller facture et règlement; refuser les affectations dépassant le solde restant. |
| Modification des rôles | Attribution ou révocation + événement d'audit. | Vérifier le rôle administrateur et l'état courant avant la mutation. |

Les opérations concurrentes sont testées sur deux sessions ou plus; les commandes doivent être recalculées après attente de verrou et ne jamais dépasser le crédit ou le stock. Les événements métier validés partagent la transaction métier. Les refus d'authentification ou d'autorisation doivent laisser une trace de sécurité durable sans exposer de données sensibles; le mécanisme exact de cette trace est vérifié avec le comportement transactionnel APEX/ORDS lors de l'implémentation.

### Écrans APEX, API et tests

- Les écrans, rôles, validations de parcours et états vides/erreurs sont détaillés dans [ui-screens.md](ui-screens.md).
- Les ressources REST versionnées, opérations, autorisations, erreurs et règles d'idempotence sont détaillées dans [contracts/rest-api.md](contracts/rest-api.md).
- Les tables normalisées, relations, contraintes et index sont détaillés dans [data-model.md](data-model.md).
- Les tests utPLSQL et Playwright, leurs gates et scénarios d'exécution sont détaillés dans [quickstart.md](quickstart.md).

### Découpage progressif

1. **Fondations**: schéma, comptes/rôles/MFA, audit, conventions de scripts, tests et configuration documentaire française. Gate: approbation des spécifications et versions cibles Oracle.
2. **Référentiels**: clients, fournisseurs, contacts, adresses et contrôles de doublons; écrans et tests des BR-001 à BR-007.
3. **Catalogue et tarification**: produits, unités, taxes, tarifs et remises; couverture BR-006 à BR-010 et BR-014 à BR-016.
4. **Ventes**: devis, crédit, commandes, réservations et transitions; couverture BR-011 à BR-022 et scénarios TEST-005 à TEST-010.
5. **Achats et stocks**: approbations, achats, réceptions, inventaires, transferts et factures fournisseurs; couverture BR-023 à BR-034.
6. **Livraisons et facturation**: expéditions partielles, factures immuables, avoirs et retours; couverture BR-035 à BR-045 et BR-049.
7. **Règlements et pilotage**: paiements partiels, affectations, échéances et tableaux de bord; couverture BR-046 à BR-048.
8. **Durcissement et mise en service**: tests de charge ciblés, reprise, sécurité, conformité française, documentation, formation et revue de release.

Chaque phase livre une tranche verticale testée (tables/changements, packages, écran APEX, contrat ORDS et tests associés) et ne commence qu'après validation de ses critères d'acceptation. Les phases 1 à 8 sont un ordre de réalisation proposé, pas une autorisation de commencer le développement.

### Gates avant implémentation

- Approbation formelle de `spec.md` et de ses cinq clarifications enregistrée le 2026-10-12 (T001); les hypothèses réglementaires et opérationnelles restantes demeurent à lever.
- Revue par le responsable comptable des obligations françaises en matière de facture, d'avoir, de numérotation, d'archivage et de facturation électronique applicable à la date de mise en service; choix de la plateforme ou des échanges requis avant conception définitive des interfaces réglementaires.
- Inventaire et gel des versions de base Oracle, APEX, ORDS, Liquibase, utPLSQL, Node.js et Playwright compatibles avec l'environnement cible; aucune version n'est déduite du poste de travail.
- Validation des seuils de crédit/remise/approbation, délais de conservation, objectifs RPO/RTO, navigateurs supportés et responsabilités d'exploitation.
- Revue de sécurité des comptes locaux, du stockage des secrets, du facteur MFA, des comptes techniques ORDS, de la récupération de compte et de l'audit des refus.

## Complexity Tracking

Sans objet: aucun écart à la constitution n'est proposé. Le découpage en modules est logique dans un seul projet Oracle, sans microservices ni dépôts séparés.
