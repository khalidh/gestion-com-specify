# Feature Specification: Gestion commerciale pour PME

**Feature Branch**: `non créée`

**Created**: 2026-10-12

**Status**: Approved

**Validated**: 2026-10-12 — approbation explicite confirmée par le responsable du projet (T001).

**Input**: User description: application complète de gestion commerciale pour PME, couvrant les référentiels, ventes, achats, stocks, livraisons, facturation, règlements, tableaux de bord et habilitations.

## User Scenarios & Testing *(mandatory)*

### Objectif et périmètre

L'application permet à une PME de gérer de bout en bout ses opérations commerciales, depuis la tenue des référentiels jusqu'au règlement des factures et au suivi de l'activité. Elle fournit une information cohérente sur les engagements clients, les achats, les niveaux de stock, les livraisons, les créances et les paiements.

Le périmètre comprend les clients et fournisseurs, les produits et tarifs, les devis, les commandes clients, les commandes d'achat et factures fournisseurs, les stocks, les livraisons, les factures et avoirs clients, les règlements clients et fournisseurs, les tableaux de bord, ainsi que les utilisateurs, rôles et habilitations.

La présente étape spécifie le comportement attendu. Elle ne produit aucun code SQL ou PL/SQL et ne vaut pas validation des spécifications par les parties prenantes.

## Clarifications

### Session 2026-10-12

- Q: Dans quel pays l’entreprise émettra-t-elle ses factures ? → A: France
- Q: La première version doit-elle accepter des ventes et achats dans plusieurs devises, ou fonctionner uniquement en euros ? → A: Euros uniquement
- Q: Comment les collaborateurs doivent-ils s’authentifier dans la première version ? → A: Comptes gérés dans l’application
- Q: L’authentification multifacteur (MFA) doit-elle être obligatoire pour tous les comptes ou seulement certains rôles ? → A: MFA obligatoire pour les administrateurs et approbateurs
- Q: La première version doit-elle gérer une seule entité juridique ou plusieurs sociétés indépendantes ? → A: Une seule entité juridique

### Acteurs et cas d'utilisation

| Acteur | Responsabilités | Cas d'utilisation principaux |
|---|---|---|
| Administrateur fonctionnel | Paramètre les référentiels, les rôles, les seuils, les séries documentaires et les comptes locaux. | UC-01, UC-02, UC-13 |
| Commercial | Gère les clients, tarifs, devis et commandes clients. | UC-01, UC-03, UC-04, UC-05 |
| Acheteur | Gère les fournisseurs, commandes d'achat et factures fournisseurs. | UC-01, UC-06 |
| Gestionnaire de stock et logistique | Suit les stocks, réceptions, transferts, préparations et livraisons. | UC-07, UC-08 |
| Comptable ou gestionnaire de facturation | Contrôle les factures, avoirs, règlements et soldes. | UC-09, UC-10, UC-11 |
| Dirigeant | Consulte les indicateurs de vente, marge, stock et trésorerie commerciale. | UC-12 |
| Auditeur ou responsable de contrôle | Consulte les événements et justificatifs autorisés en lecture seule. | UC-13, UC-14 |

Les clients et fournisseurs sont des tiers gérés par les utilisateurs internes; un portail autonome pour ces tiers n'est pas inclus dans le périmètre initial.

| ID | Cas d'utilisation | Résultat attendu |
|---|---|---|
| UC-01 | Créer, consulter, modifier ou désactiver un client ou fournisseur. | Les données sont identifiées sans doublon et l'historique commercial reste consultable. |
| UC-02 | Créer un produit, définir son type et maintenir ses tarifs. | Le produit est utilisable dans les documents selon son statut, son unité et son tarif applicable. |
| UC-03 | Préparer, transmettre et suivre un devis. | Le devis présente les prix, remises, taxes et dates applicables et peut être accepté ou refusé. |
| UC-04 | Convertir un devis accepté en commande client. | Une commande cohérente est créée sans double conversion du devis. |
| UC-05 | Créer et confirmer une commande client. | Les contrôles de crédit, tarif, remise et disponibilité sont exécutés avant engagement. |
| UC-06 | Émettre une commande d'achat, réceptionner les articles et enregistrer une facture fournisseur. | Les quantités, écarts et justificatifs d'achat restent rapprochables. |
| UC-07 | Consulter le stock, réserver, compter ou transférer des articles. | Le stock physique, réservé et disponible reste explicable par des mouvements. |
| UC-08 | Préparer une livraison totale ou partielle et la confirmer. | Les quantités livrées mettent à jour la commande et le stock sans dépasser les quantités autorisées. |
| UC-09 | Émettre, valider et consulter une facture ou un avoir client. | Le document validé est figé et son historique reste disponible. |
| UC-10 | Enregistrer et affecter un règlement client ou fournisseur. | Les règlements partiels et soldes restants sont exacts et rapprochables. |
| UC-11 | Consulter les échéances et retards de paiement. | Les soldes et dates d'échéance reflètent les factures et règlements validés. |
| UC-12 | Consulter les tableaux de bord et filtrer les indicateurs. | Les indicateurs correspondent aux documents validés et aux droits de l'utilisateur. |
| UC-13 | Créer un compte local, attribuer ou retirer un rôle et désactiver un accès. | L'accès correspond aux habilitations approuvées et peut être révoqué. |
| UC-14 | Consulter l'audit d'une opération sensible. | L'acteur autorisé peut retrouver l'acteur, la date, l'objet et le motif de l'opération. |

### User Story 1 - Tenir les référentiels commerciaux (Priority: P1)

En tant que commercial ou acheteur, je veux gérer des fiches fiables pour les clients, fournisseurs et produits afin de préparer des documents commerciaux sans ressaisie ni confusion.

**Why this priority**: Les référentiels sont requis par tous les parcours de vente, d'achat et de stock.

**Independent Test**: Créer un client, un fournisseur et un produit, vérifier les champs obligatoires et les doublons, puis désactiver une fiche et vérifier qu'elle reste consultable dans l'historique.

**Acceptance Scenarios**:

1. **Given** un utilisateur habilité et un code client libre, **When** il crée le client avec ses coordonnées obligatoires, **Then** la fiche est enregistrée et disponible dans les recherches.
2. **Given** un code déjà utilisé pour le même type de fiche, **When** l'utilisateur tente de l'enregistrer à nouveau, **Then** l'opération est refusée et le doublon est signalé.
3. **Given** un tiers désactivé ayant des documents historiques, **When** un utilisateur consulte ces documents, **Then** ils restent accessibles mais aucun nouveau document ne peut lui être attribué.

---

### User Story 2 - Construire une offre et engager une vente (Priority: P1)

En tant que commercial, je veux établir un devis puis le convertir en commande afin de formaliser l'offre faite au client et suivre son exécution.

**Why this priority**: Ce parcours transforme les besoins clients en engagements suivis et déclenche les contrôles de crédit et de stock.

**Independent Test**: Créer un devis avec plusieurs lignes, remise et date de validité, l'accepter, le convertir une seule fois, puis vérifier la commande et ses réservations.

**Acceptance Scenarios**:

1. **Given** un client actif et des tarifs applicables, **When** le commercial enregistre un devis, **Then** les prix, remises, taxes et date d'expiration sont visibles et calculés.
2. **Given** un devis accepté et non expiré, **When** le commercial le convertit, **Then** une seule commande reprend les lignes et montants acceptés.
3. **Given** une commande dépassant le plafond de crédit sans droit de dérogation, **When** le commercial tente de la confirmer, **Then** la confirmation est bloquée avec le motif et le solde d'exposition.

---

### User Story 3 - Approvisionner et maîtriser les stocks (Priority: P1)

En tant qu'acheteur ou gestionnaire de stock, je veux commander, réceptionner, compter et transférer les articles afin de connaître les quantités disponibles et les engagements fournisseurs.

**Why this priority**: La disponibilité des articles conditionne les engagements de livraison et la fiabilité des achats.

**Independent Test**: Créer une commande d'achat, en recevoir une partie, constater le stock, puis recevoir le reliquat et rapprocher la facture fournisseur.

**Acceptance Scenarios**:

1. **Given** une commande d'achat approuvée, **When** une réception partielle conforme est enregistrée, **Then** le stock accepté augmente et le reliquat de commande reste ouvert.
2. **Given** une réception supérieure à la quantité commandée, **When** un utilisateur sans habilitation tente de la valider, **Then** l'excédent est refusé et aucun stock n'est ajouté.
3. **Given** un comptage différent du stock connu, **When** un gestionnaire habilité saisit l'écart avec un motif, **Then** le stock est ajusté et le mouvement est auditable.

---

### User Story 4 - Livrer totalement ou partiellement (Priority: P1)

En tant que gestionnaire logistique, je veux préparer et confirmer des livraisons partielles ou totales afin de respecter les quantités commandées et conserver le reliquat à livrer.

**Why this priority**: Le suivi des livraisons détermine les quantités encore dues et les quantités pouvant être facturées.

**Independent Test**: Confirmer deux livraisons successives sur une commande, contrôler le stock après chacune et vérifier l'état final de la commande.

**Acceptance Scenarios**:

1. **Given** une commande confirmée et du stock réservé, **When** une livraison partielle est confirmée, **Then** seule la quantité livrée sort du stock et le reliquat reste livrable.
2. **Given** une quantité supérieure au reliquat ou au stock réservé, **When** l'utilisateur tente la livraison, **Then** la validation est refusée sans mouvement de stock.
3. **Given** le reliquat livré en plusieurs expéditions, **When** la dernière livraison est confirmée, **Then** la commande passe à l'état livré.

---

### User Story 5 - Facturer, établir des avoirs et encaisser (Priority: P1)

En tant que gestionnaire de facturation, je veux valider les factures, traiter les retours et avoirs, puis enregistrer les paiements afin de suivre précisément les créances clients.

**Why this priority**: La facturation et l'encaissement matérialisent le chiffre d'affaires et le solde dû par chaque client.

**Independent Test**: Facturer une livraison, vérifier l'immuabilité après validation, enregistrer deux paiements partiels, puis établir un avoir autorisé sur une partie de la facture.

**Acceptance Scenarios**:

1. **Given** une facture complète et équilibrée, **When** un utilisateur habilité la valide, **Then** elle reçoit une référence et devient non modifiable.
2. **Given** une facture validée avec un solde ouvert, **When** un paiement partiel est affecté, **Then** le solde restant est exact et la facture reste partiellement réglée.
3. **Given** un retour accepté lié à une facture, **When** l'avoir correspondant est validé, **Then** le montant crédité ne dépasse pas le montant encore créditable et l'événement est audité.

---

### User Story 6 - Suivre les achats et dettes fournisseurs (Priority: P2)

En tant qu'acheteur ou comptable, je veux rapprocher commandes d'achat, réceptions et factures fournisseurs afin de contrôler les quantités et montants à payer.

**Why this priority**: Le rapprochement réduit les erreurs d'achat et rend les dettes fournisseurs vérifiables.

**Independent Test**: Enregistrer une facture fournisseur conforme à une réception puis une facture présentant un écart, vérifier l'acceptation ou le blocage selon les habilitations.

**Acceptance Scenarios**:

1. **Given** une commande réceptionnée et une facture fournisseur correspondante, **When** le comptable l'enregistre, **Then** la facture est rapprochée et son échéance apparaît dans le suivi.
2. **Given** un écart de prix ou de quantité hors tolérance, **When** un utilisateur non habilité valide la facture, **Then** la validation est bloquée et l'écart est expliqué.

---

### User Story 7 - Administrer les accès et contrôler les opérations (Priority: P1)

En tant qu'administrateur ou auditeur, je veux attribuer des rôles et examiner les opérations sensibles afin de limiter les accès et de pouvoir justifier les décisions.

**Why this priority**: Les contrôles d'accès protègent les données financières et les transitions irréversibles.

**Independent Test**: Attribuer un rôle, vérifier l'accès autorisé, tenter une opération interdite et consulter l'événement d'audit correspondant.

**Acceptance Scenarios**:

1. **Given** un utilisateur sans droit de validation de facture, **When** il tente de valider une facture, **Then** l'action est refusée et le refus est consigné.
2. **Given** un utilisateur dont le rôle est révoqué, **When** il tente une nouvelle opération, **Then** l'accès est refusé sans délai fonctionnel indu.
3. **Given** une dérogation de plafond de crédit, **When** un auditeur habilité consulte l'historique, **Then** l'acteur, l'horodatage, le motif et le document sont retrouvés.
4. **Given** un compte local actif, **When** son titulaire présente des identifiants invalides, **Then** l'accès est refusé et aucune donnée métier n'est révélée.

---

### User Story 8 - Piloter l'activité (Priority: P2)

En tant que dirigeant, je veux consulter des indicateurs filtrables sur les ventes, stocks, livraisons et règlements afin de détecter rapidement les retards et écarts.

**Why this priority**: Les indicateurs facilitent les décisions quotidiennes sans remplacer les documents de référence.

**Independent Test**: Créer un jeu d'opérations validées et annulées, filtrer les indicateurs par période et vérifier les totaux ainsi que le respect des droits.

**Acceptance Scenarios**:

1. **Given** des documents validés couvrant plusieurs périodes, **When** le dirigeant sélectionne une période, **Then** seuls les indicateurs de cette période sont agrégés.
2. **Given** un utilisateur limité à un périmètre de données, **When** il ouvre un tableau de bord, **Then** aucune donnée hors périmètre n'est révélée.

### Edge Cases

- Le plafond de crédit est atteint par deux commandes simultanées: une seule opération peut consommer le dernier montant disponible; l'autre est recalculée puis bloquée ou soumise à dérogation.
- Un tarif cesse d'être valide entre la création et l'acceptation d'un devis: le devis conserve son prix accepté pendant sa période de validité, sauf règle contractuelle approuvée contraire.
- Le stock disponible devient insuffisant après la saisie d'une commande mais avant sa confirmation: la confirmation recalcule la disponibilité et bloque ou laisse une quantité en reliquat non réservée.
- Une réception ou livraison contient plusieurs lignes dont une seule est invalide: aucune validation partielle implicite n'est faite; l'utilisateur corrige ou valide explicitement les lignes admissibles.
- Une facture fournisseur est reçue sans commande d'achat: elle reste en anomalie et requiert une autorisation documentée avant rapprochement manuel.
- Un paiement dépasse le solde restant ou concerne une autre devise: l'affectation excédentaire est refusée; la somme non affectée reste distincte si elle est autorisée.
- Un retour est reçu en mauvais état: il est enregistré comme non réintégrable au stock vendable; l'avoir dépend d'une décision habilitée et justifiée.
- Une facture validée ou un événement d'audit est visé par une correction: la facture est corrigée par un avoir ou document correctif; l'audit n'est jamais réécrit.
- Une session expire pendant une opération: aucune validation financière ou de stock incomplète ne doit être présentée comme réussie.
- Un utilisateur perd son rôle pendant une session active: les opérations suivantes sont refusées selon les droits courants.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système MUST permettre la création, la recherche, la consultation, la mise à jour et la désactivation des fiches clients et fournisseurs sans supprimer les références historiques.
- **FR-002**: Le système MUST permettre de définir les produits, leur type, unité, statut, catégorie et paramètres de suivi de stock.
- **FR-003**: Le système MUST gérer en euros des tarifs datés, les remises de ligne et de document, les taxes applicables et les montants calculés de manière cohérente.
- **FR-004**: Le système MUST permettre de créer, transmettre, suivre, accepter, refuser, expirer et convertir les devis en commandes.
- **FR-005**: Le système MUST permettre de créer, contrôler, confirmer, suivre, réviser selon habilitation et annuler les commandes clients.
- **FR-006**: Le système MUST calculer l'exposition de crédit, contrôler le plafond client et appliquer les autorisations de dérogation.
- **FR-007**: Le système MUST permettre de créer et approuver des commandes d'achat, de suivre leurs reliquats, de réceptionner les articles et d'enregistrer les factures fournisseurs.
- **FR-008**: Le système MUST présenter le stock physique, réservé et disponible par produit et dépôt, et enregistrer les réceptions, sorties, transferts et ajustements.
- **FR-009**: Le système MUST permettre la préparation, la confirmation et le suivi de livraisons totales ou partielles liées à des commandes clients.
- **FR-010**: Le système MUST permettre de préparer, valider, consulter et suivre les factures clients conformément aux obligations françaises applicables à la date d'émission, et rendre les factures validées non modifiables.
- **FR-011**: Le système MUST permettre d'enregistrer et d'affecter en euros des paiements clients et fournisseurs, y compris partiels, et de présenter le solde non réglé ou non affecté.
- **FR-012**: Le système MUST permettre d'enregistrer les retours, d'en décider la réintégration au stock et d'émettre des avoirs liés aux documents concernés.
- **FR-013**: Le système MUST permettre de créer et désactiver des comptes individuels gérés dans l'application, puis de leur attribuer des rôles et permissions explicites; l'authentification fédérée est hors périmètre de la première version et le MFA est obligatoire pour les administrateurs et approbateurs.
- **FR-014**: Le système MUST conserver un audit consultable des opérations sensibles, dérogations, validations, refus et changements d'habilitation.
- **FR-015**: Le système MUST présenter des tableaux de bord filtrables sur les ventes, commandes, achats, stock, livraisons, factures et règlements selon le périmètre autorisé.
- **FR-016**: Le système MUST signaler les erreurs métier avec un motif compréhensible, l'objet concerné et la correction attendue lorsque celle-ci est possible.
- **FR-017**: Le système MUST permettre de retrouver un document par sa référence, son tiers, son statut et une période, avec des résultats limités aux droits de l'utilisateur.
- **FR-018**: Le système MUST appliquer les transitions d'état définies dans cette spécification et refuser toute transition non autorisée ou invalide.

### Règles métier

Chaque règle est stable et traçable vers une exigence fonctionnelle et un cas de test d'acceptation. Les références de tests désignent des scénarios à automatiser; elles ne constituent pas du code de test.

#### Tiers, produits et tarifs

- **BR-001** (FR-001; TEST-001): Le code d'un client MUST être unique parmi les clients, après suppression des espaces périphériques et comparaison sans distinction de casse.
- **BR-002** (FR-001; TEST-001): Une fiche client MUST comporter au minimum un nom ou une raison sociale, un code, un statut et une adresse de facturation avant d'être utilisable dans un document.
- **BR-003** (FR-001; TEST-001): Un client inactif MUST rester consultable dans l'historique mais MUST être refusé pour tout nouveau devis ou commande.
- **BR-004** (FR-001; TEST-002): Le code d'un fournisseur MUST être unique parmi les fournisseurs et sa fiche MUST comporter un nom ou une raison sociale et un statut.
- **BR-005** (FR-001; TEST-002): Une même entité juridique pouvant être à la fois cliente et fournisseur MUST être représentée par des rôles de tiers distincts, reliés si nécessaire, sans confondre ses soldes clients et fournisseurs.
- **BR-006** (FR-002; TEST-003): Le code interne d'un produit MUST être unique; un produit désactivé MUST être interdit dans les nouvelles lignes de document.
- **BR-007** (FR-002; TEST-003): Chaque produit MUST être classé comme article stockable ou service; un service MUST ne pas générer de quantité physique ni de réservation de stock.
- **BR-008** (FR-003; TEST-004): Deux tarifs applicables au même produit, tiers ou segment, devise EUR et palier de quantité MUST ne pas avoir de périodes de validité qui se chevauchent.
- **BR-009** (FR-003; TEST-004): Tout document commercial MUST conserver une photographie du prix en euros, de l'unité et de la règle de remise appliqués lors de son émission ou acceptation.
- **BR-010** (FR-003; TEST-004): Le taux ou code de taxe appliqué MUST être valide pour la date du document; les montants avant taxe, taxe et toutes taxes comprises MUST être cohérents avec ce taux.

#### Crédit, remises, devis et commandes

- **BR-011** (FR-006; TEST-005): L'exposition client MUST être calculée comme la somme des soldes des factures validées non réglées et de la valeur engagée des commandes confirmées non encore facturées, sans double comptage d'une quantité déjà facturée.
- **BR-012** (FR-006; TEST-005): La confirmation d'une commande MUST être bloquée si elle porte l'exposition au-delà du plafond de crédit, sauf dérogation donnée par un rôle explicitement autorisé.
- **BR-013** (FR-006; TEST-006): Toute dérogation au plafond MUST exiger un motif et MUST enregistrer l'acteur, l'horodatage, le plafond, l'exposition calculée et le document concerné.
- **BR-014** (FR-003, FR-006; TEST-007): Le taux de remise cumulé MUST respecter le maximum autorisé pour le rôle; tout dépassement MUST être bloqué ou soumis à une approbation distincte et auditée.
- **BR-015** (FR-003; TEST-007): Les remises de ligne MUST être appliquées avant la remise globale; la remise globale MUST être répartie de façon déterministe sur les lignes et aucune remise ne MUST rendre un montant net négatif.
- **BR-016** (FR-003; TEST-007): Le montant net de chaque ligne et le total net d'un document validé MUST être supérieur ou égal à zéro; les taxes MUST être recalculées sur les bases après remise.
- **BR-017** (FR-004; TEST-008): Un devis MUST porter une date d'expiration; il peut être accepté jusqu'à cette date incluse et MUST être refusé après cette date, sauf prolongation autorisée et tracée.
- **BR-018** (FR-004; TEST-008): L'acceptation d'un devis MUST être datée, attribuée à un acteur habilité et porter sur sa version courante non expirée.
- **BR-019** (FR-004, FR-005; TEST-009): Un devis accepté MUST pouvoir être converti en une seule commande; une seconde conversion MUST être refusée et référencer la commande existante.
- **BR-020** (FR-005; TEST-010): La confirmation d'une commande MUST vérifier que le client et les produits sont actifs, que les tarifs sont applicables et que les lignes et totaux sont cohérents.
- **BR-021** (FR-005; TEST-010): Une commande confirmée MUST ne pas être modifiée directement sur ses quantités, prix ou tiers; une révision approuvée ou une annulation suivie d'un nouveau document est requise.
- **BR-022** (FR-005; TEST-010): L'annulation d'une commande MUST être interdite pour les quantités déjà livrées; elle MUST exiger un motif et libérer les réservations des quantités restantes.

#### Stocks, achats et réceptions

- **BR-023** (FR-008; TEST-011): Le disponible d'un article dans un dépôt MUST être égal au stock physique moins les quantités réservées et le stock de sécurité configuré.
- **BR-024** (FR-008; TEST-011): La confirmation d'une commande client MUST réserver les quantités disponibles des articles stockables; les services MUST être exclus de la réservation.
- **BR-025** (FR-008; TEST-011): Une quantité indisponible MUST ne pas être réservée ni faire passer le stock physique en négatif; elle reste identifiée comme reliquat à servir.
- **BR-026** (FR-008, FR-014; TEST-012): Tout mouvement de stock MUST préciser le produit, dépôt, quantité, sens, date, origine, acteur et motif; le stock affiché MUST être justifiable par ces mouvements.
- **BR-027** (FR-008, FR-013, FR-014; TEST-012): Un ajustement issu d'un inventaire MUST requérir un rôle habilité, un motif et une trace de la quantité avant et après correction.
- **BR-028** (FR-008; TEST-013): Un transfert entre dépôts MUST produire des sorties et entrées de même quantité liées à un transfert; le transfert ne MUST pas créer de stock global.
- **BR-029** (FR-007; TEST-014): Une commande d'achat MUST être associée à un fournisseur actif et approuvée selon les seuils et délégations configurés avant transmission.
- **BR-030** (FR-007, FR-008; TEST-015): Une réception MUST référencer une commande d'achat ouverte et ne MUST pas dépasser le reliquat commandé, sauf dérogation habilitée.
- **BR-031** (FR-007, FR-013; TEST-015): Toute réception supérieure à la quantité commandée MUST exiger un rôle autorisé et un motif; la quantité excédentaire reste identifiable.
- **BR-032** (FR-007, FR-008; TEST-016): Une réception partielle MUST augmenter le stock des quantités acceptées et laisser ouverte la quantité non reçue de la commande.
- **BR-033** (FR-007; TEST-017): La référence de facture fournisseur MUST être unique pour un même fournisseur; une facture en doublon MUST être bloquée et signalée.
- **BR-034** (FR-007; TEST-017): Une facture fournisseur MUST être rapprochée des quantités reçues et des prix commandés; tout écart hors tolérance MUST être approuvé et motivé avant validation.

#### Livraisons, facturation, paiements et retours

- **BR-035** (FR-009; TEST-018): Une livraison MUST être issue d'une commande client confirmée et ne porter que sur des lignes restant à livrer.
- **BR-036** (FR-009; TEST-018): Les livraisons partielles MUST être autorisées; chaque livraison diminue le reliquat sans dépasser les quantités commandées ni les quantités disponibles et réservées.
- **BR-037** (FR-009; TEST-018): Une livraison confirmée MUST conserver une référence, une date, les lignes et quantités livrées, le destinataire et le lien vers la commande.
- **BR-038** (FR-008, FR-009; TEST-019): La confirmation d'expédition MUST diminuer le stock physique et la réservation de la quantité expédiée en créant le mouvement correspondant.
- **BR-039** (FR-005, FR-009; TEST-019): L'état de la commande MUST être calculé à partir des quantités livrées: à livrer, partiellement livrée ou entièrement livrée; une livraison annulée ne compte pas comme livrée.
- **BR-040** (FR-010; TEST-020): Une facture client MUST porter sur des quantités livrées; les services peuvent être facturés lorsqu'ils sont réalisés ou selon une condition explicitement convenue au document.
- **BR-041** (FR-010; TEST-020): Avant validation, une facture MUST vérifier l'identité et l'adresse de facturation du client, les lignes, la devise, les taxes, les totaux, les conditions d'échéance et les mentions françaises obligatoires applicables au document.
- **BR-042** (FR-010; TEST-020): Toute facture validée MUST recevoir une référence unique et non réutilisable dans une série conforme aux règles françaises de numérotation applicables.
- **BR-043** (FR-010; TEST-021): Une facture validée MUST être non modifiable et non supprimable; sa consultation conserve les valeurs, dates et lignes validées.
- **BR-044** (FR-010, FR-012; TEST-021): Une erreur sur une facture validée MUST être corrigée par un avoir ou document correctif lié; la facture d'origine MUST rester inchangée.
- **BR-045** (FR-010, FR-011; TEST-021): L'échéance MUST être calculée selon les conditions de paiement du client et la date de facture; le retard est calculé à partir du solde restant après affectation des règlements.
- **BR-046** (FR-011; TEST-022): Un règlement client ou fournisseur MUST avoir un montant strictement positif en euros, une date, un tiers et un moyen de règlement autorisé.
- **BR-047** (FR-011; TEST-023): Un règlement partiel MUST être accepté; l'affectation cumulée à une facture MUST ne pas dépasser son solde restant.
- **BR-048** (FR-011; TEST-023): Un règlement MUST être affecté uniquement à des documents du même tiers et de la même devise; toute somme non affectée MUST rester visible comme solde à rapprocher.
- **BR-049** (FR-012; TEST-024): Un retour MUST référencer une livraison ou facture, préciser les quantités et le résultat du contrôle; un avoir lié MUST ne pas dépasser le montant restant créditable et une quantité retournée non vendable MUST ne pas réintégrer le stock disponible.
- **BR-050** (FR-013, FR-014; TEST-025): Chaque collaborateur MUST utiliser un compte local individuel actif; l'accès MUST être refusé par défaut sans authentification et permission explicites. Les comptes ayant un rôle d'administrateur ou d'approbateur MUST utiliser le MFA. Toute opération sensible, tentative refusée, dérogation ou modification de rôle MUST être auditée avec l'acteur, l'horodatage, l'action, l'objet et le motif disponible, et l'audit MUST être protégé contre la modification par les utilisateurs fonctionnels.

### Workflows et transitions d'état

Toute transition non énumérée ci-dessous est refusée. Les changements d'état financiers ou de stock sont atomiques du point de vue de l'utilisateur: un échec ne peut laisser croire qu'une validation a réussi.

| Objet | Transitions autorisées | Conditions principales |
|---|---|---|
| Client ou fournisseur | Actif → Inactif; Inactif → Actif | Rôle autorisé; aucun document historique n'est supprimé. |
| Devis | Brouillon → Émis → Accepté; Émis → Refusé, Expiré ou Annulé | L'acceptation requiert un devis courant non expiré; toute annulation est motivée. |
| Commande client | Brouillon → Confirmée → Partiellement livrée → Livrée → Clôturée | Confirmation sous réserve des contrôles client, crédit, remise et stock; l'état de livraison suit les quantités. Annulation possible avant livraison des quantités restantes. |
| Commande d'achat | Brouillon → À approuver → Approuvée → Transmise → Partiellement réceptionnée → Réceptionnée → Clôturée | Approbation selon délégation; réception rapprochée des lignes et reliquats. |
| Facture fournisseur | Saisie → À rapprocher → Rapprochée → Validée → Partiellement réglée → Réglée | Les écarts hors tolérance nécessitent une décision habilitée; une facture validée n'est pas réécrite. |
| Livraison | À préparer → Préparée → Expédiée → Livrée | Expédition diminue les quantités réservées et physiques; annulation possible avant expédition uniquement. |
| Facture client | Brouillon → Validée → Partiellement réglée → Réglée | La validation vérifie les totaux et attribue une référence; après validation, correction uniquement par document lié. |
| Avoir client | Brouillon → Validé → Partiellement affecté → Affecté | Référence obligatoire à une facture d'origine; le cumul reste dans le montant créditable. |
| Règlement | Saisi → Enregistré → Partiellement affecté → Affecté | Montant, tiers, devise et affectations sont contrôlés; correction par annulation ou contrepassation tracée. |
| Retour | Demandé → Reçu → Contrôlé → Accepté ou Refusé | La quantité, l'état, la décision de remise en stock et l'éventuel avoir sont conservés. |
| Compte utilisateur | Créé → Actif → Désactivé | Chaque compte est individuel; seul un rôle autorisé gère les accès; la désactivation révoque les accès futurs sans effacer l'audit. |

### Cas d'erreur et réponses attendues

| Situation | Réponse attendue |
|---|---|
| Code de tiers ou produit déjà utilisé | Refuser l'enregistrement, indiquer le type de doublon et permettre la recherche de la fiche existante. |
| Tiers ou produit inactif | Refuser son utilisation dans un nouveau document et préserver l'accès aux documents historiques. |
| Plafond de crédit dépassé | Bloquer la confirmation, présenter l'exposition et le plafond; proposer une demande de dérogation sans la réaliser automatiquement. |
| Remise supérieure au droit de l'utilisateur | Refuser ou soumettre à approbation; afficher le seuil et le rôle requis. |
| Tarif absent, expiré ou ambigu | Empêcher l'émission/validation et demander la sélection ou correction d'un tarif valide. |
| Stock indisponible ou réservation concurrente | Recalculer le disponible, empêcher le stock négatif et indiquer la quantité livrable ou en reliquat. |
| Réception supérieure au reliquat d'achat | Refuser la quantité excédentaire sauf dérogation tracée. |
| Livraison supérieure au reliquat ou au réservé | Refuser la confirmation sans mouvement de stock. |
| Facture fournisseur en doublon ou non rapprochée | Bloquer sa validation et identifier le fournisseur, la référence ou l'écart à résoudre. |
| Modification ou suppression d'une facture validée | Refuser l'action et orienter l'utilisateur vers un avoir ou document correctif. |
| Paiement non positif, devise/tiers incorrects ou affectation excédentaire | Refuser l'affectation, afficher le solde admissible et préserver toute somme non affectée autorisée. |
| Retour sans justificatif ou quantité excessive | Refuser la validation ou demander une approbation motivée; ne pas modifier le stock avant décision. |
| Permission absente ou session révoquée | Refuser l'action, ne révéler aucune donnée non autorisée et journaliser la tentative sensible. |
| Échec pendant une validation | Signaler l'échec sans afficher un nouvel état validé ni un mouvement partiel. |

### Exigences non fonctionnelles

- **NFR-001 Performance**: Pour 50 utilisateurs simultanés et jusqu'à 50 000 fiches de tiers et produits, 95 % des recherches courantes MUST répondre en moins de 2 secondes et 95 % des validations documentaires en moins de 3 secondes, hors indisponibilité externe.
- **NFR-002 Disponibilité**: Le service MUST viser au minimum 99,5 % de disponibilité mensuelle, hors fenêtres de maintenance annoncées.
- **NFR-003 Sécurité**: Les accès MUST appliquer le moindre privilège, une séparation des rôles incompatible avec l'auto-approbation des opérations sensibles et une protection des données en transit et stockées. Les comptes MUST être individuels, le MFA MUST être exigé pour les administrateurs et approbateurs, et les secrets d'authentification ne MUST jamais être conservés en clair.
- **NFR-004 Auditabilité**: 100 % des opérations sensibles listées dans BR-013, BR-027 et BR-050 MUST être retrouvables par acteur, période, objet et action; la recherche ne doit pas autoriser la modification de l'audit.
- **NFR-005 Intégrité**: 100 % des tests de rapprochement MUST démontrer la cohérence entre quantités commandées, reçues, réservées, livrées et facturées ainsi qu'entre montants facturés, réglés et restant dus.
- **NFR-006 Continuité**: Les sauvegardes et procédures de reprise MUST viser une perte maximale de données de 24 heures (RPO) et une reprise du service en 4 heures (RTO); ces seuils sont à confirmer selon les moyens de l'entreprise.
- **NFR-007 Utilisabilité**: Les parcours de devis, commande, réception, livraison et règlement MUST être réalisables au clavier; les erreurs MUST être compréhensibles par un utilisateur non technique et rédigées en français.
- **NFR-008 Compatibilité**: Les parcours principaux MUST fonctionner sur les versions supportées des navigateurs de bureau courants retenus par l'entreprise; les formats de date, nombre et devise MUST être cohérents dans toute l'application.
- **NFR-009 Confidentialité**: Les données financières, coordonnées et informations d'accès MUST être visibles uniquement par les rôles autorisés; les exports MUST appliquer les mêmes droits que les écrans.
- **NFR-010 Maintenabilité fonctionnelle**: Les statuts, seuils d'approbation, plafonds, règles de remise et séries documentaires destinés à varier MUST être paramétrables par un rôle autorisé et documentés en français.

### Cas de test d'acceptation et traçabilité

Les identifiants ci-dessous sont des scénarios d'acceptation à automatiser. La matrice établit la chaîne exigée entre exigences, règles métier et tests. Une règle est testée dans le contexte nominal et, lorsqu'elle porte un contrôle, dans son cas de refus.

| Test | Vérification d'acceptation |
|---|---|
| TEST-001 | Créer, rechercher, désactiver puis consulter un client; vérifier champs obligatoires, code unique et conservation historique. |
| TEST-002 | Créer fournisseur et entité mixte client/fournisseur; vérifier l'unicité, la liaison et la séparation des soldes. |
| TEST-003 | Créer un article stockable et un service; vérifier code unique, statut et absence de stock pour un service. |
| TEST-004 | Appliquer tarifs datés en EUR, paliers et taxe; vérifier absence de chevauchement et photographie du prix sur document. |
| TEST-005 | Calculer l'exposition à partir de factures et commandes non facturées; vérifier blocage au plafond et absence de double comptage. |
| TEST-006 | Autoriser une dérogation de crédit; vérifier rôle, motif, valeurs calculées et audit. |
| TEST-007 | Appliquer remises de ligne et globale avec différents rôles; vérifier cumul, ordre de calcul et refus d'un net négatif. |
| TEST-008 | Accepter un devis le jour d'expiration puis après expiration; vérifier date, acteur et refus hors validité. |
| TEST-009 | Convertir un devis accepté en commande puis répéter la conversion; vérifier l'unicité de la commande. |
| TEST-010 | Confirmer, réviser et annuler une commande; vérifier contrôles, approbations, motifs et libération des réservations. |
| TEST-011 | Réserver des quantités concurrentes; vérifier calcul du disponible, reliquat et absence de stock négatif. |
| TEST-012 | Enregistrer un mouvement et un ajustement d'inventaire; vérifier motif, permissions, quantités avant/après et audit. |
| TEST-013 | Transférer des articles entre dépôts; vérifier les mouvements liés et l'invariance du stock global. |
| TEST-014 | Soumettre une commande d'achat à approbation; vérifier fournisseur actif, seuil et délégation. |
| TEST-015 | Réceptionner au reliquat puis tenter un excédent sans permission; vérifier refus et absence de mouvement indu. |
| TEST-016 | Réceptionner partiellement puis le reliquat; vérifier stock accepté et état de commande d'achat. |
| TEST-017 | Enregistrer deux fois une facture fournisseur et rapprocher une facture présentant un écart; vérifier doublon et approbation. |
| TEST-018 | Livrer une commande en plusieurs livraisons; vérifier reliquat, limites de quantité et états. |
| TEST-019 | Confirmer une expédition puis l'annuler après expédition; vérifier mouvement unique et transition interdite. |
| TEST-020 | Préparer et valider une facture; vérifier lignes, identité, taxes, mentions françaises applicables, totaux et référence conforme et unique. |
| TEST-021 | Modifier une facture validée, établir un correctif et recalculer une échéance; vérifier immuabilité et soldes. |
| TEST-022 | Enregistrer des paiements client et fournisseur valides en euros; vérifier date, tiers et moyen. |
| TEST-023 | Affecter un paiement en plusieurs fois, dépasser le solde puis laisser un reliquat non affecté; vérifier soldes et refus. |
| TEST-024 | Enregistrer un retour vendable et non vendable, puis établir un avoir partiel; vérifier limite créditable et stock. |
| TEST-025 | Tester l'authentification par compte local, le MFA des administrateurs et approbateurs, l'accès autorisé/refusé, la révocation de rôle et la consultation d'audit; vérifier moindre privilège et protection des traces. |

| Exigence | Règles métier liées | Tests liés |
|---|---|---|
| FR-001 | BR-001 à BR-005 | TEST-001, TEST-002 |
| FR-002 | BR-006, BR-007 | TEST-003 |
| FR-003 | BR-008 à BR-010, BR-014 à BR-016 | TEST-004, TEST-007 |
| FR-004 | BR-017 à BR-019 | TEST-008, TEST-009 |
| FR-005 | BR-019 à BR-022, BR-039 | TEST-009, TEST-010, TEST-019 |
| FR-006 | BR-011 à BR-013 | TEST-005, TEST-006 |
| FR-007 | BR-029 à BR-034 | TEST-014 à TEST-017 |
| FR-008 | BR-023 à BR-028, BR-032, BR-038 | TEST-011 à TEST-013, TEST-016, TEST-019 |
| FR-009 | BR-035 à BR-039 | TEST-018, TEST-019 |
| FR-010 | BR-040 à BR-045 | TEST-020, TEST-021 |
| FR-011 | BR-045 à BR-048 | TEST-021 à TEST-023 |
| FR-012 | BR-044, BR-049 | TEST-021, TEST-024 |
| FR-013 | BR-027, BR-029, BR-031, BR-050 | TEST-006, TEST-012, TEST-014, TEST-015, TEST-025 |
| FR-014 | BR-013, BR-026, BR-027, BR-050 | TEST-006, TEST-012, TEST-025 |
| FR-015 | BR-011, BR-023, BR-032, BR-039, BR-045 à BR-048 | TEST-005, TEST-011, TEST-016, TEST-019, TEST-021 à TEST-023 |
| FR-016 | BR-012, BR-014, BR-025, BR-030, BR-034, BR-043, BR-047, BR-050 | TEST-005 à TEST-007, TEST-011, TEST-015, TEST-017, TEST-021, TEST-023, TEST-025 |
| FR-017 | BR-001, BR-004, BR-006, BR-037, BR-042, BR-050 | TEST-001 à TEST-003, TEST-018, TEST-020, TEST-025 |
| FR-018 | BR-017 à BR-050 | TEST-008 à TEST-025 |
| NFR-001 | Aucune règle métier spécifique; contraintes de performance des parcours FR-001 à FR-018 | Mesurer 95e percentile selon le jeu de charge défini. |
| NFR-002 | Aucune règle métier spécifique; disponibilité des parcours FR-001 à FR-018 | Mesurer la disponibilité mensuelle et exclure les maintenances annoncées. |
| NFR-003 | BR-050 | TEST-025 et revue des contrôles de sécurité. |
| NFR-004 | BR-013, BR-027, BR-050 | TEST-006, TEST-012, TEST-025. |
| NFR-005 | BR-023 à BR-049 | TEST-011 à TEST-024. |
| NFR-006 | Aucune règle métier spécifique; continuité du service | Exercice de restauration mesurant RPO et RTO. |
| NFR-007 | FR-016, BR-050 | Tests clavier et revue de compréhension en français. |
| NFR-008 | FR-003, FR-017 | Vérifier les parcours sur les navigateurs retenus et les formats affichés. |
| NFR-009 | BR-050 | TEST-025 et vérification des écrans et exports par rôle. |
| NFR-010 | BR-008, BR-010, BR-013, BR-014, BR-029, BR-050 | TEST-004, TEST-006, TEST-007, TEST-014, TEST-025. |

### Key Entities *(include if feature involves data)*

- **Tiers**: Client ou fournisseur avec identité, coordonnées, statut, conditions commerciales et rôles éventuels.
- **Produit**: Article stockable ou service avec code, unité, statut, catégorie, taxes et paramètres de stock applicables.
- **Tarif**: Prix daté selon produit, devise, segment ou tiers, palier de quantité et conditions.
- **Devis**: Proposition versionnée au client, avec lignes, montants, validité, décision et lien éventuel vers une commande.
- **Commande client**: Engagement commercial avec lignes, quantités, tarifs, contrôle de crédit, réservations et reliquats.
- **Commande d'achat**: Engagement fournisseur avec lignes, approbations, réceptions et reliquats.
- **Mouvement de stock**: Entrée, sortie, transfert ou ajustement justifié, localisé par dépôt et lié à son origine.
- **Livraison**: Expédition totale ou partielle d'une commande, avec lignes, quantités, date et destinataire.
- **Facture client**: Document financier validé, immuable, référencé, avec échéance et solde.
- **Facture fournisseur**: Document reçu d'un fournisseur et rapproché des achats et réceptions.
- **Avoir**: Document correctif lié à une facture, avec motif et montant encore créditable.
- **Règlement et affectation**: Paiement reçu ou émis et ses affectations aux factures correspondantes.
- **Utilisateur, rôle et permission**: Identité interne, attribution de rôles et actions autorisées.
- **Événement d'audit**: Trace protégée d'une action ou tentative sensible, de son acteur, de sa date, de son objet et de son motif.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Au moins 90 % des utilisateurs représentatifs terminent les parcours de création d'un devis, confirmation d'une commande, réception, livraison et affectation d'un paiement sans assistance lors des tests d'acceptation.
- **SC-002**: Au moins 95 % des recherches répondent en moins de 2 secondes et des validations documentaires en moins de 3 secondes avec la charge et le volume définis dans NFR-001.
- **SC-003**: 100 % des scénarios de livraison partielle, réception partielle, paiement partiel et retour aboutissent à des quantités et soldes conformes aux règles attendues.
- **SC-004**: 100 % des tests de correction démontrent qu'une facture validée reste inchangée et qu'une correction est représentée par un document lié.
- **SC-005**: 100 % des scénarios d'accès négatif refusent les opérations interdites et produisent les traces d'audit prévues.
- **SC-006**: Chaque exigence fonctionnelle et non fonctionnelle est reliée à ses règles métier applicables et à un moyen de vérification dans la matrice de traçabilité.
- **SC-007**: Les utilisateurs métier peuvent expliquer le solde d'une commande, d'un article en stock et d'une facture à partir des documents et mouvements consultables.

## Assumptions

- La première version gère une seule entité juridique, avec plusieurs dépôts possibles; la consolidation multi-sociétés est hors périmètre initial.
- Tous les documents de la première version sont libellés en euros (EUR); les ventes et achats en devises étrangères sont hors périmètre initial.
- La France est le pays de facturation initial. Les catégories de TVA, mentions obligatoires, règles de numérotation et durées de conservation applicables MUST être conformes aux obligations françaises en vigueur et validées par le responsable comptable.
- Les conditions de paiement, seuils d'approbation, plafonds de crédit et limites de remise sont administrables; leurs valeurs commerciales restent à fournir par l'entreprise.
- Les commandes clients standard sont facturées sur les quantités livrées. Les acomptes, abonnements, ventes récurrentes et factures sans livraison sont hors périmètre initial, sauf décision contraire.
- Les règlements sont saisis par les utilisateurs; l'initiation bancaire, le rapprochement automatique bancaire et le paiement en ligne ne sont pas inclus.
- Le retour physique peut donner lieu à une remise en stock, une mise en quarantaine ou un rebut selon le contrôle; la décision financière d'avoir reste distincte.
- Les utilisateurs sont des collaborateurs internes disposant de comptes individuels gérés dans l'application; l'authentification fédérée, le portail client/fournisseur et l'application mobile dédiée ne sont pas inclus dans cette spécification initiale.
- Les objectifs NFR de disponibilité, charge, reprise et volumétrie sont des seuils de cadrage à valider par les responsables avant approbation de la spécification.
- Les obligations françaises de facturation, de conservation et de protection des données doivent être revues par un professionnel compétent avant validation finale.