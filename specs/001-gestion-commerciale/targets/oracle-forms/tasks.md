---
description: "Tâches de préparation et de réalisation de la cible Oracle Forms"
---

# Tâches : Cible Oracle Forms

**Entrées**: [spécification cible](spec.md), [plan Forms](plan.md), [profil technique](profile.yaml), spécification métier parente.

**Prérequis**: plan parent, modèle conceptuel et packages métier partagés; voir les gates de `plan.md`.

**Règle de sécurité**: tâches d'implémentation bloquées jusqu'à fermeture de T001-T006, approbation de l'exception constitutionnelle et validation d'un environnement isolé. Ces tâches ne remplacent pas les changements de schéma/packages du [plan parent](../../tasks.md).

Chaque tâche suit `- [ ] Tnnn [P] [USn] description avec chemin`. Les IDs BR, FR, TEST et UI référencent la spécification parent sans être renumérotés.

## Phase 1 : Profil et setup

**But**: transformer l'accord de cible en profil de déploiement vérifiable et préparer les outils sans coder le métier.

- [ ] T001 Confirmer Forms/Reports, patch set, version Database, runtime, hébergement, format des modules, identité/MFA, rapports et harnais UI dans `specs/001-gestion-commerciale/targets/oracle-forms/profile.yaml`.
- [ ] T002 Faire approuver et enregistrer l'exception à la constitution, limitée à la présentation Oracle Forms de cette feature, dans `specs/001-gestion-commerciale/targets/oracle-forms/profile.yaml` et le registre de décisions du projet.
- [ ] T003 Définir les répertoires sources, exclusions des artefacts compilés et commandes de compilation/revue Forms dans `forms/README.md` et le pipeline CI du dépôt.
- [ ] T004 Définir un harnais automatisable pour les parcours UI Forms et les résultats attendus dans `tests/forms/README.md`.
- [ ] T005 Valider en environnement Oracle isolé les grants de moindre privilège, packages PL/SQL appelés et mécanisme de contexte utilisateur; consigner les preuves dans `tests/forms/environment-validation.md`.
- [ ] T006 Confirmer que les gates métier, réglementaires et de mise en œuvre de la spécification parent sont levés dans `specs/001-gestion-commerciale/targets/oracle-forms/profile.yaml` avant le début des modules.

**Checkpoint**: aucune source Forms métier n'est créée avant clôture de T001-T006.

## Phase 2 : User Story 7 - Administrer les accès et contrôler les opérations (P1)

**But**: sécuriser les parcours Forms avant d'exposer les actions métier.

**Test indépendant**: TEST-025 passe via les packages partagés; le parcours Forms refuse l'accès sans identité/permission, applique MFA aux rôles privilégiés et permet une consultation d'audit autorisée.

- [ ] T007 [P] [US7] Définir les cas d'interface TEST-025 pour connexion, rôles, MFA, révocation et consultation d'audit dans `tests/forms/security/TEST-025.yaml`.
- [ ] T008 [US7] Construire le module d'accès, le menu par permissions et le contexte utilisateur Forms pour les pages 001/120 dans `forms/modules/FRM_SECURITY.fmb` et `forms/menus/MNU_GC.mmb`; appeler `PKG_GC_SECURITY` sans implémenter de contrôle concurrent.
- [ ] T009 [US7] Construire la consultation d'audit en lecture seule et vérifier TEST-025 dans `forms/modules/FRM_AUDIT.fmb` et `tests/forms/security/TEST-025.yaml`.

## Phase 3 : User Story 1 - Tenir les référentiels commerciaux (P1, MVP Forms)

**But**: créer, rechercher et consulter tiers, produits et tarifs avec les contrôles existants.

**Test indépendant**: TEST-001 à TEST-004 passent par les parcours Forms et les services; fiches inactives restent consultables mais ne sont pas sélectionnables pour un nouveau document.

- [ ] T010 [P] [US1] Définir les cas UI TEST-001 à TEST-004 et leurs rôles dans `tests/forms/referentials/TEST-001-004.yaml`.
- [ ] T011 [US1] Construire recherche et fiche client/fournisseur, adresses et contacts (pages 030/031), en appelant `PKG_GC_PARTY`, dans `forms/modules/FRM_PARTIES.fmb`.
- [ ] T012 [US1] Construire recherche et fiche produit (page 040) avec type, statut et cohérence article/service, en appelant `PKG_GC_CATALOG`, dans `forms/modules/FRM_PRODUCTS.fmb`.
- [ ] T013 [US1] Construire maintenance des tarifs datés et affichage des règles de remise (page 041), en appelant les packages de tarification, puis exécuter TEST-001 à TEST-004 dans `forms/modules/FRM_PRICES.fmb` et `tests/forms/referentials/TEST-001-004.yaml`.

## Phase 4 : User Story 2 - Construire une offre et engager une vente (P1)

**But**: créer devis et commandes sans déplacer les règles de crédit, prix ou stock hors packages.

**Test indépendant**: TEST-005 à TEST-010 couvrent exposition, dérogation, remise, expiration, conversion unique, confirmation et annulation.

- [ ] T014 [P] [US2] Définir les cas UI TEST-005 à TEST-010 et les transitions visibles dans `tests/forms/sales/TEST-005-010.yaml`.
- [ ] T015 [US2] Construire l'éditeur/recherche de devis (page 050), ses lignes, états et actions, en appelant `PKG_GC_QUOTES`, dans `forms/modules/FRM_QUOTES.fmb`.
- [ ] T016 [US2] Construire commandes, exposition crédit et demande d'approbation (pages 060/061), en appelant `PKG_GC_SALES_ORDERS` et les packages d'approbation; vérifier TEST-005 à TEST-010 dans `forms/modules/FRM_SALES_ORDERS.fmb` et `tests/forms/sales/TEST-005-010.yaml`.

## Phase 5 : User Story 3 - Approvisionner et maîtriser les stocks (P1)

**But**: rendre visibles commandes d'achat, réceptions et quantités par dépôt avec mouvements justifiables.

**Test indépendant**: TEST-011 à TEST-016 passent; aucun stock négatif, réception excédentaire non autorisée ou transfert déséquilibré.

- [ ] T017 [P] [US3] Définir les cas UI TEST-011 à TEST-016 pour concurrence, inventaire, transfert et réception partielle dans `tests/forms/inventory/TEST-011-016.yaml`.
- [ ] T018 [US3] Construire consultation et opérations de stock par dépôt (pages 080/081) en appelant `PKG_GC_INVENTORY` dans `forms/modules/FRM_INVENTORY.fmb`.
- [ ] T019 [US3] Construire commandes d'achat et réceptions partielles (pages 070/071) en appelant `PKG_GC_PROCUREMENT`; vérifier TEST-011 à TEST-016 dans `forms/modules/FRM_PROCUREMENT.fmb` et `tests/forms/inventory/TEST-011-016.yaml`.

## Phase 6 : User Story 4 - Livrer totalement ou partiellement (P1)

**But**: préparer, confirmer et suivre les livraisons avec reliquats conformes.

**Test indépendant**: TEST-018 et TEST-019 passent; une expédition confirmée n'est comptée qu'une fois et une transition interdite est refusée.

- [ ] T020 [P] [US4] Définir les cas UI TEST-018 et TEST-019 dans `tests/forms/delivery/TEST-018-019.yaml`.
- [ ] T021 [US4] Construire préparation et suivi de livraison (page 090) en appelant `PKG_GC_DELIVERY`; vérifier TEST-018/019 dans `forms/modules/FRM_DELIVERIES.fmb` et `tests/forms/delivery/TEST-018-019.yaml`.

## Phase 7 : User Story 5 - Facturer, établir des avoirs et encaisser (P1)

**But**: présenter les factures validées en lecture seule et permettre les opérations autorisées d'avoir et de règlement.

**Test indépendant**: TEST-020 à TEST-024 passent; facture validée immuable, soldes exacts et retours conformes.

- [ ] T022 [P] [US5] Définir les cas UI TEST-020 à TEST-024 dans `tests/forms/billing/TEST-020-024.yaml`.
- [ ] T023 [US5] Construire factures clients, consultation immuable et retours/avoirs (pages 100/102), en appelant les packages de facturation, dans `forms/modules/FRM_CUSTOMER_BILLING.fmb`.
- [ ] T024 [US5] Construire règlements et affectations partielles (page 110), en appelant `PKG_GC_PAYMENTS`; vérifier TEST-020 à TEST-024 dans `forms/modules/FRM_PAYMENTS.fmb` et `tests/forms/billing/TEST-020-024.yaml`.

## Phase 8 : User Story 6 - Suivre les achats et dettes fournisseurs (P2)

**But**: rapprocher facture fournisseur, achat et réception avec approbation des écarts.

**Test indépendant**: TEST-017 refuse les doublons et exige une approbation motivée pour tout écart hors tolérance.

- [ ] T025 [P] [US6] Définir les cas UI de rapprochement TEST-017 dans `tests/forms/procurement/TEST-017.yaml`.
- [ ] T026 [US6] Construire le rapprochement des factures fournisseurs (page 101) en appelant `PKG_GC_PROCUREMENT`; vérifier TEST-017 dans `forms/modules/FRM_SUPPLIER_INVOICES.fmb` et `tests/forms/procurement/TEST-017.yaml`.

## Phase 9 : User Story 8 - Piloter l'activité (P2)

**But**: présenter les indicateurs filtrés issus de vues et packages autorisés.

**Test indépendant**: filtres, agrégats et restrictions de périmètre sont conformes à FR-015/FR-017 et NFR-009.

- [ ] T027 [P] [US8] Définir les cas de test de tableaux de bord, filtres et droits dans `tests/forms/dashboard/acceptance.yaml`.
- [ ] T028 [US8] Construire accueil, navigation et tableaux de bord (pages 010/020/021/022) sur des sources de lecture autorisées; vérifier les cas d'acceptation dans `forms/modules/FRM_DASHBOARD.fmb` et `tests/forms/dashboard/acceptance.yaml`.

## Phase 10 : Durcissement et validation

**But**: vérifier qualité, compatibilité et exploitation avant une éventuelle décision de mise en service.

- [ ] T029 [P] Mesurer NFR-001 avec 50 utilisateurs et 50 000 fiches selon l'environnement validé dans `tests/forms/performance/load-test-plan.yaml`.
- [ ] T030 Vérifier navigation clavier, messages français, formats EUR/date, matrice des postes et droits sur tous les modules dans `tests/forms/acceptance/accessibility-and-locale.yaml`.
- [ ] T031 Documenter compilation reproductible, publication, restauration et procédure de retour arrière dans `forms/README.md` et `specs/001-gestion-commerciale/targets/oracle-forms/quickstart.md`.

## Dépendances et stratégie

- T001-T006 bloquent toutes les tâches d'implémentation Forms.
- US7 (T007-T009) précède les parcours métier accessibles aux utilisateurs.
- US1 (T010-T013) est le MVP Forms; les autres stories consomment ses référentiels.
- US2, US3 et US6 dépendent des packages métier correspondants du plan parent; US4 dépend des ventes et stocks; US5 dépend des livraisons, de la facturation et des paiements.
- Les tests de chaque story et les modules sans fichiers partagés peuvent être préparés en parallèle après fermeture des fondations; les compilations et modifications d'un même module restent séquentielles.
- Priorité de livraison: sécurité, référentiels, ventes, achats/stocks, livraisons, facturation/règlements, factures fournisseurs, pilotage.

**MVP proposé**: T001-T013, incluant prérequis, parcours sécurisé et référentiels; aucune mise en service avant revue indépendante et levée des gates du profil.