---
description: "Tâches de réalisation de la gestion commerciale pour PME"
---

# Tâches : Gestion commerciale pour PME

**Entrées**: documents de conception de `specs/001-gestion-commerciale/`

**Prérequis**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: utPLSQL, Playwright et contrats REST sont requis par la spécification et la constitution.

**Organisation**: tâches regroupées par user story, dans l'ordre des priorités et des dépendances.

## Format

Chaque tâche suit strictement le format `- [ ] Tnnn [P] [USn] description avec chemin`. `[P]` est réservé aux tâches exécutables en parallèle sans dépendance sur un fichier partagé. Les phases Setup, Foundational et Polish n'ont pas d'étiquette de story.

Tous les travaux d'implémentation ci-dessous restent bloqués jusqu'à la validation métier explicite de `specs/001-gestion-commerciale/spec.md`, à l'approbation du plan et à la levée des gates réglementaires pertinents.

## Phase 1 : Setup

**But**: obtenir l'approbation préalable et préparer la structure du dépôt sans écrire de logique métier.

- [x] T001 Enregistrer l'approbation formelle de `specs/001-gestion-commerciale/spec.md` et du gate de mise en œuvre dans `specs/001-gestion-commerciale/spec.md` avant toute modification de `database/`, `apex/`, `ords/` ou `tests/`.
- [x] T002 [P] Initialiser le changelog maître Liquibase et les conventions de changesets dans `database/changelog/db.changelog-master.yaml`.
- [x] T003 [P] Documenter les conventions de nommage, compilation et ordre des packages dans `database/README.md`.
- [x] T004 [P] Documenter l'export APEX et le versionnage des définitions ORDS dans `apex/exports/README.md` et `ords/definitions/README.md`.
- [x] T005 [P] Initialiser le projet Playwright Test et sa configuration d'environnements dans `tests/playwright/package.json` et `tests/playwright/playwright.config.ts`.
- [x] T006 [P] Définir le registre des suites et les conventions utPLSQL dans `tests/utplsql/README.md`.

---

## Phase 2 : Foundational

**But**: fournir les primitives communes bloquant l'ensemble des stories: erreurs, sécurité, audit, stock disponible/réservé et outillage de test.

- [x] T007 [P] Créer le package commun de codes d'erreur métier et de corrélation dans `database/packages/common/pkg_gc_errors.pks.sql` et `database/packages/common/pkg_gc_errors.pkb.sql`.
- [x] T008 [P] Créer les tables de comptes, rôles, permissions, associations, facteur MFA et audit dans `database/changelog/changesets/001_security_audit.sql`; respecter « login unique », « aucun secret en clair » et l'audit en insertion seule.
- [x] T009 Créer le package de contexte utilisateur et de vérification des permissions dans `database/packages/security/pkg_gc_security.pks.sql` et `database/packages/security/pkg_gc_security.pkb.sql`; refuser par défaut toute permission absente.
- [x] T010 Créer le package d'audit append-only dans `database/packages/security/pkg_gc_audit.pks.sql` et `database/packages/security/pkg_gc_audit.pkb.sql`; couvrir acteur, date, action, objet et motif.
- [x] T011 [P] Créer le socle des dépôts, soldes et réservations dans `database/changelog/changesets/002_inventory_core.sql`; respecter « PK composite produit/dépôt », « quantités non négatives » et une seule devise EUR.
- [x] T012 Ajouter les fixtures synthétiques et helpers de tests communs dans `tests/utplsql/support/gc_test_data.sql` et `tests/playwright/fixtures/auth.fixture.ts`; exclure toute donnée de production.
- [x] T013 Configurer la session APEX, les privilèges ORDS et les grants de lecture sur vues/packages dans `apex/exports/application/security.sql` et `ords/definitions/security.yaml`; interdire le DML direct des tables métier.
- [ ] T014 Valider l'installation Liquibase, les grants et les packages communs sur un schéma Oracle isolé dans `tests/database/validate-foundation.ps1`.

**Checkpoint**: aucune story ne démarre avant approbation de T001 et validation des prérequis de T014.

---

## Phase 3 : User Story 7 - Administrer les accès et contrôler les opérations (P1)

**But**: fournir les comptes locaux, rôles, MFA privilégié et consultation d'audit nécessaires aux utilisateurs métier.

**Test indépendant**: créer un compte local, vérifier un accès permis et refusé, révoquer un rôle, exiger MFA pour un administrateur/approbateur et retrouver l'événement d'audit.

### Tests

- [ ] T015 [P] [US7] Écrire les tests utPLSQL de cycle de vie des comptes, permissions, MFA privilégié et audit dans `tests/utplsql/security/test_gc_security.pks.sql` et `tests/utplsql/security/test_gc_security.pkb.sql`.
- [ ] T016 [P] [US7] Écrire les tests Playwright de connexion locale, compte invalide, accès refusé et parcours MFA dans `tests/playwright/security/local-auth.spec.ts`.

### Réalisation

- [ ] T017 [US7] Implémenter création/désactivation de comptes, attribution/révocation de rôles, MFA administrateur/approbateur et journalisation dans `database/packages/security/pkg_gc_security.pkb.sql`.
- [ ] T018 [P] [US7] Construire les pages APEX connexion, gestion des comptes, rôles et enrôlement MFA dans `apex/exports/application/pages/001-login.sql` et `apex/exports/application/pages/120-users-roles.sql`.
- [ ] T019 [P] [US7] Exposer les contrats ORDS de création de compte et d'attribution de rôle avec `USER_ADMIN` dans `ords/definitions/users.yaml`.
- [ ] T020 [US7] Construire la consultation d'audit en lecture seule avec filtres acteur/période/objet dans `apex/exports/application/pages/121-audit.sql` et `database/views/v_gc_audit_events.sql`.
- [ ] T021 [US7] Exécuter TEST-025 et vérifier révocation immédiate, MFA des rôles privilégiés et absence de mutation de l'audit dans `tests/playwright/security/local-auth.spec.ts` et `tests/utplsql/security/test_gc_security.pkb.sql`.

**Checkpoint**: TEST-025 passe et les tentatives non autorisées sont refusées sans fuite de données.

---

## Phase 4 : User Story 1 - Tenir les référentiels commerciaux (P1, MVP métier)

**But**: créer et retrouver clients, fournisseurs, produits, taxes, tarifs et remises.

**Test indépendant**: créer un client, un fournisseur et un produit, vérifier les doublons et contraintes, créer un tarif EUR et consulter les fiches historiques après désactivation.

### Tests

- [ ] T022 [P] [US1] Écrire les tests utPLSQL TEST-001, TEST-002, TEST-003 et TEST-004 pour champs requis, codes uniques, type article/service, tarif EUR, périodes et taxe dans `tests/utplsql/referentials/test_gc_party_catalog_pricing.pks.sql` et `tests/utplsql/referentials/test_gc_party_catalog_pricing.pkb.sql`.
- [ ] T023 [P] [US1] Écrire les parcours Playwright de création/recherche de tiers, produit, tarif et doublon dans `tests/playwright/referentials/master-data.spec.ts`.

### Réalisation

- [ ] T024 [US1] Créer les tables tiers, adresses, contacts, client/fournisseur, produit, taxe et tarif dans `database/changelog/changesets/003_referentials_catalog_pricing.sql`; ajouter les FK produit différées de `002_inventory_core.sql` et respecter « code client unique sans distinction de casse », « SKU unique », « quantité positive », « article/service cohérent » et « périodes de validité non chevauchantes ».
- [ ] T025 [P] [US1] Implémenter les packages de tiers et catalogue dans `database/packages/referentials/pkg_gc_party.pks.sql`, `database/packages/referentials/pkg_gc_party.pkb.sql`, `database/packages/referentials/pkg_gc_catalog.pks.sql` et `database/packages/referentials/pkg_gc_catalog.pkb.sql`.
- [ ] T026 [P] [US1] Implémenter tarifs, paliers, remises et taxes datées dans `database/packages/pricing/pkg_gc_pricing.pks.sql`, `database/packages/pricing/pkg_gc_pricing.pkb.sql`, `database/packages/pricing/pkg_gc_tax.pks.sql` et `database/packages/pricing/pkg_gc_tax.pkb.sql`.
- [ ] T027 [US1] Construire les pages APEX clients et fournisseurs, avec adresse obligatoire avant usage documentaire, dans `apex/exports/application/pages/030-parties.sql`.
- [ ] T028 [US1] Construire les pages APEX catalogue, produits et tarifs EUR avec détection des chevauchements dans `apex/exports/application/pages/040-products.sql` et `apex/exports/application/pages/041-prices.sql`.
- [ ] T029 [P] [US1] Publier les ressources ORDS tiers, produits et prix applicables conformes à `specs/001-gestion-commerciale/contracts/rest-api.md` dans `ords/definitions/parties.yaml`, `ords/definitions/products.yaml` et `ords/definitions/prices.yaml`.
- [ ] T030 [US1] Exécuter TEST-001 à TEST-004 en utPLSQL et Playwright et corriger les écarts dans `tests/utplsql/referentials/` et `tests/playwright/referentials/master-data.spec.ts`.

**Checkpoint**: les référentiels et tarifs sont utilisables indépendamment; TEST-001 à TEST-004 passent.

---

## Phase 5 : User Story 2 - Construire une offre et engager une vente (P1)

**But**: établir un devis et le convertir en commande avec contrôle de remise, crédit et réservation de stock.

**Test indépendant**: créer et accepter un devis EUR, le convertir une fois, confirmer une commande avec stock de fixture, vérifier plafond de crédit, remises et réservation.

### Tests

- [ ] T031 [P] [US2] Écrire les tests utPLSQL TEST-005, TEST-006, TEST-007, TEST-008, TEST-009 et TEST-010 pour exposition, dérogation, remise, expiration, conversion unique et transitions de commande dans `tests/utplsql/sales/test_gc_quotes_orders.pks.sql` et `tests/utplsql/sales/test_gc_quotes_orders.pkb.sql`.
- [ ] T032 [P] [US2] Écrire les parcours Playwright devis accepté, commande confirmée, refus crédit et remise hors rôle dans `tests/playwright/sales/quotes-orders.spec.ts`.
- [ ] T033 [P] [US2] Écrire les tests de contrat REST des actions devis/commande/idempotence dans `tests/playwright/api/sales-contract.spec.ts`.

### Réalisation

- [ ] T034 [US2] Créer les tables devis, lignes, commandes clients et lignes avec snapshots dans `database/changelog/changesets/004_sales_documents.sql`; respecter « devis accepté converti au plus une fois », « quantité positive », « quantités livrées/facturées bornées par quantité commandée » et snapshots EUR/taxe/remise.
- [ ] T035 [P] [US2] Implémenter émission, expiration, acceptation et conversion unique du devis dans `database/packages/sales/pkg_gc_quotes.pks.sql` et `database/packages/sales/pkg_gc_quotes.pkb.sql`.
- [ ] T036 [US2] Implémenter confirmation, crédit, remise, réservation et annulation de commande dans `database/packages/sales/pkg_gc_sales_orders.pks.sql` et `database/packages/sales/pkg_gc_sales_orders.pkb.sql`; verrouiller le client puis les soldes produit/dépôt dans l'ordre défini par `plan.md`.
- [ ] T037 [US2] Construire les pages APEX devis, commande, état de crédit et demande de dérogation dans `apex/exports/application/pages/050-quotes.sql`, `apex/exports/application/pages/060-sales-orders.sql` et `apex/exports/application/pages/061-approvals.sql`.
- [ ] T038 [US2] Publier les ressources ORDS devis et commandes, avec codes d'erreur métier et idempotence, dans `ords/definitions/quotes.yaml` et `ords/definitions/sales-orders.yaml`.
- [ ] T039 [US2] Tester en sessions concurrentes l'exposition client, l'allocation des dernières unités et le rollback atomique dans `tests/utplsql/sales/test_gc_sales_order_concurrency.pks.sql` et `tests/utplsql/sales/test_gc_sales_order_concurrency.pkb.sql`.
- [ ] T040 [US2] Exécuter TEST-005 à TEST-010 et valider indépendamment le parcours devis-commande dans `tests/utplsql/sales/` et `tests/playwright/sales/quotes-orders.spec.ts`.

**Checkpoint**: aucun dépassement de crédit/remise, double conversion ou réservation excédentaire; TEST-005 à TEST-010 passent.

---

## Phase 6 : User Story 3 - Approvisionner et maîtriser les stocks (P1)

**But**: passer des commandes d'achat, réceptionner partiellement, compter et transférer les articles avec un stock justifiable.

**Test indépendant**: réceptionner un achat en plusieurs fois, vérifier le stock physique/disponible, refuser un excédent non autorisé et rapprocher un inventaire/transfert.

### Tests

- [ ] T041 [P] [US3] Écrire les tests utPLSQL TEST-011, TEST-012, TEST-013, TEST-014, TEST-015 et TEST-016 sur disponibilité, réservation, ajustement, transfert et réceptions partielles dans `tests/utplsql/inventory/test_gc_inventory_procurement.pks.sql` et `tests/utplsql/inventory/test_gc_inventory_procurement.pkb.sql`.
- [ ] T042 [P] [US3] Écrire les parcours Playwright achat, réception partielle, inventaire et transfert dans `tests/playwright/inventory/procurement-stock.spec.ts`.

### Réalisation

- [ ] T043 [US3] Créer commandes d'achat, lignes, réceptions, lignes de réception et mouvements dans `database/changelog/changesets/005_procurement_stock_movements.sql`; respecter « réception cumulée contrôlée », « quantités non négatives », « reliquat commandé » et mouvements liés au dépôt/origine.
- [ ] T044 [US3] Implémenter commande d'achat, délégations, réception partielle et reliquat dans `database/packages/procurement/pkg_gc_procurement.pks.sql` et `database/packages/procurement/pkg_gc_procurement.pkb.sql`.
- [ ] T045 [US3] Compléter disponibilité, mouvements, ajustements motivés, transferts et réservations dans `database/packages/inventory/pkg_gc_inventory.pks.sql` et `database/packages/inventory/pkg_gc_inventory.pkb.sql`; garantir « stock global inchangé par transfert » et « disponible = physique - réservé - sécurité ».
- [ ] T046 [US3] Construire commandes d'achat, réception, consultation stock, inventaire et transferts dans `apex/exports/application/pages/070-purchase-orders.sql`, `apex/exports/application/pages/071-receipts.sql`, `apex/exports/application/pages/080-inventory.sql` et `apex/exports/application/pages/081-counts-transfers.sql`.
- [ ] T047 [US3] Publier les ressources ORDS d'achat, réception, disponibilité, ajustement et transfert dans `ords/definitions/procurement.yaml` et `ords/definitions/inventory.yaml`.
- [ ] T048 [P] [US3] Ajouter les tests de contrat REST des réceptions partielles et opérations de stock autorisées/refusées dans `tests/playwright/api/inventory-contract.spec.ts`.
- [ ] T049 [US3] Tester les réceptions et réservations concurrentes sur deux sessions sans stock négatif ni double réception dans `tests/utplsql/inventory/test_gc_inventory_concurrency.pks.sql` et `tests/utplsql/inventory/test_gc_inventory_concurrency.pkb.sql`.
- [ ] T050 [US3] Exécuter TEST-011, TEST-012, TEST-013, TEST-014, TEST-015 et TEST-016 et valider le rapprochement soldes/mouvements dans `tests/utplsql/inventory/` et `tests/playwright/inventory/procurement-stock.spec.ts`.

**Checkpoint**: TEST-011 à TEST-016 passent; chaque quantité physique est explicable par mouvements et chaque reliquat reste visible.

---

## Phase 7 : User Story 4 - Livrer totalement ou partiellement (P1)

**But**: préparer et confirmer des expéditions liées aux commandes en maintenant les reliquats et mouvements cohérents.

**Test indépendant**: livrer une commande en deux expéditions, vérifier stock/réservation après chaque expédition et refuser une quantité au-delà du reliquat.

### Tests

- [ ] T051 [P] [US4] Écrire les tests utPLSQL TEST-018 et TEST-019 pour livraison partielle, dépassement, mouvement unique et transition interdite dans `tests/utplsql/delivery/test_gc_delivery.pks.sql` et `tests/utplsql/delivery/test_gc_delivery.pkb.sql`.
- [ ] T052 [P] [US4] Écrire le parcours Playwright de deux livraisons successives et d'un refus de dépassement dans `tests/playwright/delivery/partial-deliveries.spec.ts`.

### Réalisation

- [ ] T053 [US4] Créer livraisons et lignes avec liens source et quantités dans `database/changelog/changesets/006_deliveries.sql`; respecter « somme expédiée bornée par reliquat » et liens vers commande/ligne/dépôt.
- [ ] T054 [US4] Implémenter préparation, expédition, confirmation atomique, sortie de stock et mise à jour du reliquat dans `database/packages/delivery/pkg_gc_delivery.pks.sql` et `database/packages/delivery/pkg_gc_delivery.pkb.sql`.
- [ ] T055 [US4] Construire la page APEX de préparation et suivi de livraison dans `apex/exports/application/pages/090-deliveries.sql`.
- [ ] T056 [US4] Publier les ressources ORDS de création et expédition de livraison dans `ords/definitions/deliveries.yaml`.
- [ ] T057 [US4] Exécuter TEST-018 et TEST-019 et rapprocher les quantités livrées, réservées et physiques dans `tests/utplsql/delivery/` et `tests/playwright/delivery/partial-deliveries.spec.ts`.

**Checkpoint**: une livraison partielle conserve le reliquat, une expédition décompte une seule fois et TEST-018/019 passent.

---

## Phase 8 : User Story 5 - Facturer, établir des avoirs et encaisser (P1)

**But**: valider des factures immuables, traiter retours/avoirs et affecter des règlements partiels.

**Test indépendant**: facturer une livraison, prouver l'immuabilité, enregistrer deux paiements partiels et créditer un retour sans dépasser le solde créditable.

### Tests

- [ ] T058 [P] [US5] Écrire les tests utPLSQL TEST-020, TEST-021, TEST-022, TEST-023 et TEST-024 pour mentions françaises, numéro unique, facture immuable, paiements partiels et avoir/retour dans `tests/utplsql/billing/test_gc_billing_payments.pks.sql` et `tests/utplsql/billing/test_gc_billing_payments.pkb.sql`.
- [ ] T059 [P] [US5] Écrire les parcours Playwright facture validée, modification refusée, affectation partielle et avoir de retour dans `tests/playwright/billing/invoices-payments-returns.spec.ts`.
- [ ] T060 [P] [US5] Écrire les tests de contrat REST de validation de facture, avoir et affectation paiement dans `tests/playwright/api/billing-contract.spec.ts`.

### Réalisation

- [ ] T061 [US5] Créer factures clients, lignes, avoirs, lignes d'avoir, paiements, affectations et séquences dans `database/changelog/changesets/007_customer-billing-payments.sql`; respecter « série+numéro unique et non réutilisable », « montant strictement positif », « somme affectée ≤ règlement » et « somme reçue ≤ solde facture ».
- [ ] T062 [US5] Implémenter calcul, mentions françaises, attribution de référence, validation et immuabilité des factures dans `database/packages/billing/pkg_gc_billing.pks.sql` et `database/packages/billing/pkg_gc_billing.pkb.sql`.
- [ ] T063 [US5] Implémenter paiements EUR client/fournisseur, affectations partielles et solde non affecté dans `database/packages/payments/pkg_gc_payments.pks.sql` et `database/packages/payments/pkg_gc_payments.pkb.sql`; refuser devise/tiers incompatibles et dépassement du solde.
- [ ] T064 [US5] Implémenter retours, décision de remise en stock et avoir lié à la facture dans `database/packages/billing/pkg_gc_billing.pkb.sql` et `database/packages/inventory/pkg_gc_inventory.pkb.sql`.
- [ ] T065 [US5] Construire les pages APEX factures client, retours/avoirs et règlements dans `apex/exports/application/pages/100-customer-invoices.sql`, `apex/exports/application/pages/102-returns-credit-notes.sql` et `apex/exports/application/pages/110-payments.sql`.
- [ ] T066 [US5] Publier les ressources ORDS factures client, validation, avoirs, paiements et affectations dans `ords/definitions/customer-billing.yaml` et `ords/definitions/payments.yaml`.
- [ ] T067 [US5] Exécuter TEST-020, TEST-021, TEST-022, TEST-023 et TEST-024 et vérifier la concordance facture/avoir/paiement/stock dans `tests/utplsql/billing/` et `tests/playwright/billing/invoices-payments-returns.spec.ts`.

**Checkpoint**: les factures validées sont non modifiables; paiements partiels et avoirs respectent leurs plafonds; TEST-020 à TEST-024 passent.

---

## Phase 9 : User Story 6 - Suivre les achats et dettes fournisseurs (P2)

**But**: enregistrer les factures fournisseurs, rapprocher achats/réceptions et suivre dettes et paiements.

**Test indépendant**: saisir une facture conforme, refuser un doublon, soumettre un écart hors tolérance à approbation et affecter un règlement fournisseur partiel.

### Tests

- [ ] T068 [P] [US6] Écrire les tests utPLSQL TEST-017 et les cas de règlement fournisseur de TEST-022 pour doublons, rapprochement, écart et solde dans `tests/utplsql/procurement/test_gc_supplier_invoices.pks.sql` et `tests/utplsql/procurement/test_gc_supplier_invoices.pkb.sql`.
- [ ] T069 [P] [US6] Écrire les parcours Playwright facture fournisseur conforme, doublon, écart à approuver et règlement partiel dans `tests/playwright/procurement/supplier-invoices.spec.ts`.

### Réalisation

- [ ] T070 [US6] Créer les factures fournisseurs et lignes rapprochables dans `database/changelog/changesets/008_supplier-invoices.sql`; respecter « référence unique par fournisseur » et conserver les quantités/prix reçus et l'écart approuvé.
- [ ] T071 [US6] Étendre `PKG_GC_PROCUREMENT` au rapprochement, contrôle de doublon, tolérances et validation des factures fournisseurs dans `database/packages/procurement/pkg_gc_procurement.pks.sql` et `database/packages/procurement/pkg_gc_procurement.pkb.sql`.
- [ ] T072 [US6] Construire l'écran APEX de rapprochement et suivi des factures fournisseurs dans `apex/exports/application/pages/101-supplier-invoices.sql`.
- [ ] T073 [US6] Publier les contrats `POST /supplier-invoices` et `POST /supplier-invoices/{id}/validate` dans `ords/definitions/supplier-invoices.yaml` selon `specs/001-gestion-commerciale/contracts/rest-api.md`.
- [ ] T074 [US6] Exécuter TEST-017 et le rapprochement des règlements fournisseurs dans `tests/utplsql/procurement/` et `tests/playwright/procurement/supplier-invoices.spec.ts`.

**Checkpoint**: aucune facture fournisseur en doublon ni écart hors tolérance ne peut être validé sans approbation motivée.

---

## Phase 10 : User Story 8 - Piloter l'activité (P2)

**But**: consulter les indicateurs de vente, stock, achats, livraison et finance selon la période et le rôle.

**Test indépendant**: alimenter des documents validés et annulés, filtrer par période/rôle, vérifier les agrégats et l'absence d'accès aux données hors périmètre.

### Tests

- [ ] T075 [P] [US8] Écrire les tests utPLSQL des agrégats filtrés et de l'exclusion des documents non validés dans `tests/utplsql/reporting/test_gc_reporting.pks.sql` et `tests/utplsql/reporting/test_gc_reporting.pkb.sql`.
- [ ] T076 [P] [US8] Écrire les parcours Playwright de filtres période, tableaux de bord par rôle et drill-down autorisé dans `tests/playwright/reporting/dashboards.spec.ts`.

### Réalisation

- [ ] T077 [US8] Implémenter les vues de lecture et `PKG_GC_REPORTING` pour les indicateurs ventes, stock, livraisons, créances et dettes dans `database/views/reporting/` et `database/packages/reporting/pkg_gc_reporting.pks.sql` / `database/packages/reporting/pkg_gc_reporting.pkb.sql`.
- [ ] T078 [US8] Construire les tableaux de bord APEX commercial, stock/achats et financier dans `apex/exports/application/pages/020-sales-dashboard.sql`, `apex/exports/application/pages/021-stock-purchasing-dashboard.sql` et `apex/exports/application/pages/022-financial-dashboard.sql`.
- [ ] T079 [US8] Publier les ressources ORDS de consultation des tableaux de bord avec filtres et pagination dans `ords/definitions/dashboards.yaml`.
- [ ] T080 [US8] Vérifier NFR-009, SC-006 et les droits de lecture des agrégats dans `tests/playwright/reporting/dashboards.spec.ts` et `tests/utplsql/reporting/test_gc_reporting.pkb.sql`.

**Checkpoint**: les tableaux de bord ne comptent que les documents pertinents et n'exposent aucun montant hors rôle.

---

## Phase 11 : Polish et contrôles transversaux

**But**: lever les gates opérationnels, réglementaires et qualité avant release; cette phase ne remplace pas l'approbation métier préalable.

- [ ] T081 Faire valider par le responsable comptable les mentions françaises, numérotation, conservation et périmètre de facturation électronique dans `specs/001-gestion-commerciale/research.md` et `specs/001-gestion-commerciale/contracts/rest-api.md` avant mise en service.
- [ ] T082 [P] Exécuter le test de charge NFR-001 sur 50 utilisateurs et 50 000 fiches, puis analyser les plans et index dans `tests/performance/commerce-load.md` et `database/README.md`.
- [ ] T083 [P] Revoir MFA, permissions minimales, séparation demandeur/approbateur, exports et traces d'audit dans `specs/001-gestion-commerciale/quickstart.md` et `tests/security/security-review.md`.
- [ ] T084 [P] Définir et tester sauvegarde/restauration avec les cibles RPO/RTO approuvées dans `ops/backup-restore.md`.
- [ ] T085 Exécuter la matrice complète FR/NFR → BR → TEST et confirmer une couverture de toutes les BR-001 à BR-050 dans `specs/001-gestion-commerciale/spec.md` et les rapports `tests/utplsql/` / `tests/playwright/`.
- [ ] T086 Exécuter le guide de validation, archiver les résultats et mettre à jour la documentation de release en français dans `specs/001-gestion-commerciale/quickstart.md` et `docs/releases/1.0.0.md`.

---

## Dépendances et ordre d'exécution

### Dépendances entre phases

- **Setup (Phase 1)**: T001 est le gate d'approbation; les autres tâches de structure attendent son succès.
- **Foundational (Phase 2)**: dépend de Setup; fournit les erreurs, accès, audit et réservations minimales et bloque les stories.
- **US7 (Phase 3)**: dépend de la base sécurité/audit; établit les comptes et rôles utilisables par tous.
- **US1 (Phase 4)**: dépend de Foundation et US7; fournit tiers, produits, tarifs et taxes.
- **US2 (Phase 5)**: dépend de US1 et des primitives de réservation en Foundation; utilise des fixtures de stock initial.
- **US3 (Phase 6)**: dépend de US1; fournit achats, réceptions et mouvements opérationnels, sans dépendre des devis.
- **US4 (Phase 7)**: dépend de US2 et US3 pour commandes, réservations et stock.
- **US5 (Phase 8)**: dépend de US4 pour facturer les quantités livrées et de Foundation pour les permissions.
- **US6 (Phase 9)**: dépend de US3 pour commandes/réceptions fournisseurs et de US5 pour les paiements partagés.
- **US8 (Phase 10)**: dépend des sources métier livrées en US2 à US6 et des contrôles de US7.
- **Polish (Phase 11)**: dépend de toutes les stories incluses dans la release et de l'approbation des gates réglementaires/opérationnels.

### Graphe de dépendances

```text
T001 → Setup → Foundational → US7 → US1
                                  ├──→ US2 ──┐
                                  └──→ US3 ──┴→ US4 → US5 → US6
                                                     └──────→ US8 (après US2-US6)
Toutes les stories retenues → Polish/release
```

US2 et US3 peuvent être réalisés en parallèle après US1 si l'équipe conserve l'interface stock de Foundation; US4 attend les deux. US6 s'appuie sur le paiement commun livré dans US5.

## Opportunités de parallélisation

| Story | Tâches parallèles proposées | Critère de test indépendant |
|---|---|---|
| US7 | T015 et T016; après Foundation, T018 et T019 touchent des exports séparés. | TEST-025: compte local, MFA privilégié, permissions refusées/révoquées et audit consultable. |
| US1 | T022 et T023; après T024, T025 et T026 sont séparables par package. | TEST-001 à TEST-004: tiers/produits uniques, tarif EUR daté et taxe cohérente. |
| US2 | T031, T032 et T033; après T034, T035 peut avancer séparément de T036. | TEST-005 à TEST-010: devis expiré/accepté, conversion unique, crédit/remise et réservation. |
| US3 | T041 et T042; après T043, T044 et T045 sont séparables par domaine. | TEST-011 à TEST-016: disponible, réception partielle, ajustement/transfert et absence de négatif. |
| US4 | T051 et T052; après T053, l'écran T055 peut avancer avec le contrat T056. | TEST-018/019: expéditions partielles, reliquat, mouvement unique et transitions interdites. |
| US5 | T058, T059 et T060; après T061, facturation T062 et paiements T063 sont séparables. | TEST-020 à TEST-024: facture immuable, paiements partiels, retours/avoirs plafonnés. |
| US6 | T068 et T069; après T070, écran T072 et contrat T073 touchent des fichiers séparés. | TEST-017: doublon bloqué et écart fournisseur soumis à approbation. |
| US8 | T075 et T076; vues T077 et pages T078 sont parallélisables après définition des agrégats. | Filtres/périodes, inclusion des seuls documents attendus et restriction par rôle selon UC-12/SC-006. |

## Exemples de lancement parallèle

Ces exemples n'ignorent jamais les dépendances de phase; ils indiquent seulement les tâches sans fichier partagé ni prérequis l'une sur l'autre.

```text
US7 : T015 + T016
US1 : T022 + T023; puis T025 + T026
US2 : T031 + T032 + T033
US3 : T041 + T042
US4 : T051 + T052
US5 : T058 + T059 + T060
US6 : T068 + T069
US8 : T075 + T076
```

## Stratégie d'implémentation

### MVP

Le premier incrément démontrable comprend Foundation, US7 et US1: accès sécurisés, référentiels et catalogue/tarifs. Il prouve l'administration des identités et la qualité des données, mais ne constitue pas encore un cycle de vente complet.

### Livraison incrémentale

1. Obtenir l'approbation métier et lever le gate T001.
2. Livrer Foundation puis US7 et US1; exécuter TEST-001 à TEST-004 et TEST-025.
3. Livrer US2 et US3 en parallèle possible; exécuter TEST-005 à TEST-016.
4. Livrer US4 puis US5; exécuter TEST-018 à TEST-024.
5. Livrer US6 et US8; vérifier TEST-017, UC-12 et SC-006.
6. Terminer Polish, revue française, tests de charge/restauration et matrice de traçabilité avant toute mise en service.

## Validation du format

- 86 tâches, identifiants séquentiels T001 à T086.
- Les tâches Setup/Foundation/Polish ne portent pas d'étiquette US; toutes les tâches des phases de story portent `[US1]` à `[US8]`.
- `[P]` n'est présent que lorsque les fichiers et prérequis permettent l'exécution parallèle.
- Chaque tâche commence par `- [ ] Tnnn` et cite un ou plusieurs chemins précis du dépôt.