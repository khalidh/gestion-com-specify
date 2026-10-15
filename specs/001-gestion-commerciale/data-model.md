# Modèle de données conceptuel

## Conventions

- Préfixe proposé `GC_`; les noms et types Oracle définitifs seront validés par DBA lors de la conception physique.
- Tables normalisées autour des entités et associations; les attributs copiés sur une ligne de document sont des instantanés commerciaux immuables, pas des doublons de référentiel modifiables.
- Chaque table porte une clé technique `*_ID` et les colonnes d'audit de création/modification nécessaires. Les lignes d'audit utilisent un modèle append-only distinct.
- Une seule entité juridique et une devise EUR en v1; plusieurs dépôts sont autorisés.
- Aucune instruction DDL ou SQL de création n'est produite dans ce document.

## Tables par domaine

### Référentiels et tarification

| Table | Attributs métier principaux | Clés et relations |
|---|---|---|
| `GC_PARTY` | `PARTY_ID`, `PARTY_CODE`, `LEGAL_NAME`, `DISPLAY_NAME`, `STATUS`, `VAT_ID`, `CREATED_AT` | PK `PARTY_ID`; code unique; parent commun aux clients/fournisseurs. |
| `GC_PARTY_ADDRESS` | `ADDRESS_ID`, `PARTY_ID`, `ADDRESS_TYPE`, lignes d'adresse, `POSTAL_CODE`, `CITY`, `COUNTRY_CODE`, période d'effet | PK; FK vers party; index party/type/validité; plusieurs adresses par tiers. |
| `GC_PARTY_CONTACT` | `CONTACT_ID`, `PARTY_ID`, nom, fonction, courriel, téléphone, statut | PK; FK vers party; aucune unicité globale sur courriel. |
| `GC_CUSTOMER` | `PARTY_ID`, `CREDIT_LIMIT_EUR`, `PAYMENT_TERM_ID`, `DEFAULT_PRICE_LIST_ID`, `CREDIT_STATUS` | PK/FK `PARTY_ID`; extension un-à-un de party. |
| `GC_SUPPLIER` | `PARTY_ID`, `PAYMENT_TERM_ID`, `DEFAULT_CURRENCY` | PK/FK `PARTY_ID`; v1 impose EUR. |
| `GC_PAYMENT_TERM` | `PAYMENT_TERM_ID`, code, libellé, jours/décalage, statut | PK; référencé par client/fournisseur et instantané sur facture. |
| `GC_PRODUCT` | `PRODUCT_ID`, `SKU`, `LABEL`, `PRODUCT_TYPE`, `UNIT_CODE`, `STATUS`, `TAX_CATEGORY_ID`, `STOCK_TRACKED`, `SAFETY_STOCK` | PK; SKU unique; contrainte article/service et suivi stock cohérents. |
| `GC_TAX_CATEGORY` | `TAX_CATEGORY_ID`, code, libellé, statut | PK; référencé par produit et lignes documentaires. |
| `GC_TAX_RATE` | `TAX_RATE_ID`, `TAX_CATEGORY_ID`, taux, date début/fin, pays | PK; FK category; index category/pays/date; périodes chevauchantes refusées par service. |
| `GC_PRICE_LIST` | `PRICE_LIST_ID`, code, libellé, tiers/segment optionnel, devise EUR, statut | PK; code unique; aucune autre devise admise en v1. |
| `GC_PRICE_RULE` | `PRICE_RULE_ID`, `PRICE_LIST_ID`, `PRODUCT_ID`, quantité minimale, prix, validité début/fin | PK; FK vers liste/produit; index produit/liste/validité; règle de non-chevauchement contrôlée sous verrou. |

### Ventes, achats et stock

| Table | Attributs métier principaux | Clés et relations |
|---|---|---|
| `GC_QUOTE` | `QUOTE_ID`, numéro, `CUSTOMER_ID`, dates émission/expiration, état, totaux EUR, version | PK; FK client; numéro unique; index client/état/date. |
| `GC_QUOTE_LINE` | `QUOTE_LINE_ID`, `QUOTE_ID`, `PRODUCT_ID`, ligne, quantité, instantanés libellé/unité/prix/remise/taxe/net | PK; FK devis/produit; quantité positive; ordre de ligne unique dans le devis. |
| `GC_SALES_ORDER` | `SALES_ORDER_ID`, numéro, `CUSTOMER_ID`, `QUOTE_ID` nullable, état, dates, totaux EUR, version | PK; FK client/devis; devis converti au plus une fois; index client/état/date. |
| `GC_SALES_ORDER_LINE` | `SALES_ORDER_LINE_ID`, `SALES_ORDER_ID`, `QUOTE_LINE_ID` nullable, `PRODUCT_ID`, quantité, instantanés de prix/taxe, quantité livrée/facturée | PK; FK commande/produit; quantités livrées/facturées bornées par quantité commandée. |
| `GC_PURCHASE_ORDER` | `PURCHASE_ORDER_ID`, numéro, `SUPPLIER_ID`, état, demandeur, approbateur, dates, totaux EUR | PK; FK fournisseur; index fournisseur/état/date. |
| `GC_PURCHASE_ORDER_LINE` | `PURCHASE_ORDER_LINE_ID`, `PURCHASE_ORDER_ID`, `PRODUCT_ID`, quantité, prix EUR, quantité reçue, taxe | PK; FK commande/produit; réception cumulée contrôlée. |
| `GC_RECEIPT` | `RECEIPT_ID`, numéro, `PURCHASE_ORDER_ID`, `WAREHOUSE_ID`, état, date, réceptionnaire | PK; FK commande/dépôt; index commande/date. |
| `GC_RECEIPT_LINE` | `RECEIPT_LINE_ID`, `RECEIPT_ID`, `PURCHASE_ORDER_LINE_ID`, quantité acceptée, quantité refusée, motif | PK; FK réception/ligne achat; quantités non négatives et total dans le reliquat autorisé. |
| `GC_WAREHOUSE` | `WAREHOUSE_ID`, code, libellé, statut, adresse | PK; code unique. |
| `GC_STOCK_BALANCE` | `PRODUCT_ID`, `WAREHOUSE_ID`, quantité physique, quantité réservée, version | PK composite produit/dépôt; FK produit/dépôt; quantités non négatives; projection recalculable. |
| `GC_STOCK_MOVEMENT` | `MOVEMENT_ID`, produit, dépôt, type, quantité signée, origine, référence origine, horodatage, acteur, motif | PK; FK produit/dépôt; index produit/dépôt/date et origine; journal des mouvements. |
| `GC_STOCK_RESERVATION` | `RESERVATION_ID`, `SALES_ORDER_LINE_ID`, produit, dépôt, quantité, état, dates | PK; FK ligne/produit/dépôt; index produit/dépôt/état; somme réservée bornée par disponibilité. |
| `GC_DELIVERY` | `DELIVERY_ID`, numéro, `SALES_ORDER_ID`, état, date prévue, date expédition, destinataire | PK; FK commande; index commande/état/date. |
| `GC_DELIVERY_LINE` | `DELIVERY_LINE_ID`, `DELIVERY_ID`, `SALES_ORDER_LINE_ID`, produit, dépôt, quantité expédiée | PK; FK livraison/ligne commande; somme expédiée bornée par reliquat. |

### Facturation et règlements

| Table | Attributs métier principaux | Clés et relations |
|---|---|---|
| `GC_CUSTOMER_INVOICE` | `CUSTOMER_INVOICE_ID`, numéro/série, `CUSTOMER_ID`, dates facture/échéance, état, totaux EUR, adresse/mentions instantanées, date validation | PK; FK client; série+numéro unique et non réutilisable; index client/état/échéance. |
| `GC_CUSTOMER_INVOICE_LINE` | `CUSTOMER_INVOICE_LINE_ID`, `CUSTOMER_INVOICE_ID`, ligne livraison/source, produit, instantanés libellé/unité/prix/remise/taxe, quantité et montants EUR | PK; FK facture; lignes verrouillées après validation. |
| `GC_SUPPLIER_INVOICE` | `SUPPLIER_INVOICE_ID`, `SUPPLIER_ID`, référence fournisseur, dates, état, totaux EUR, commande/réception source | PK; FK fournisseur; référence unique par fournisseur; index fournisseur/échéance/état. |
| `GC_SUPPLIER_INVOICE_LINE` | `SUPPLIER_INVOICE_LINE_ID`, `SUPPLIER_INVOICE_ID`, ligne achat/réception, produit, quantité, prix, taxe et écart | PK; FK facture; écarts avec statut d'approbation et motif. |
| `GC_CREDIT_NOTE` | `CREDIT_NOTE_ID`, numéro/série, facture d'origine, état, date, motif, totaux EUR, date validation | PK; FK facture; numéro unique; cumul des avoirs borné par montant créditable. |
| `GC_CREDIT_NOTE_LINE` | `CREDIT_NOTE_LINE_ID`, `CREDIT_NOTE_ID`, ligne facture d'origine, produit, quantité, montants EUR, décision stock | PK; FK avoir/ligne facture; quantité créditée bornée par quantité facturée restante. |
| `GC_PAYMENT` | `PAYMENT_ID`, tiers, rôle client/fournisseur, référence, date, moyen, montant EUR, état, acteur | PK; FK tiers; montant strictement positif; index tiers/date/état. |
| `GC_PAYMENT_ALLOCATION` | `ALLOCATION_ID`, `PAYMENT_ID`, document cible, type document, montant EUR, date, acteur | PK; FK règlement; somme affectée ≤ règlement; somme reçue ≤ solde facture. |
| `GC_DOCUMENT_SEQUENCE` | type document, préfixe, prochain numéro, année/période, statut | PK par type/période; accès sérialisé; politique française à valider avant production. |
| `GC_APPROVAL` | `APPROVAL_ID`, type/référence document, état, demandeur, approbateur, horodatages, décision, motif | PK; index état/demandeur/date; approbateur distinct du demandeur pour opérations sensibles. |

### Identités, sécurité et exploitation

| Table | Attributs métier principaux | Clés et relations |
|---|---|---|
| `GC_USER_ACCOUNT` | `USER_ID`, login normalisé, nom, statut, vérificateur d'identifiants protégé, dates dernier accès/verrouillage | PK; login unique; aucun secret en clair; statut contrôlé. |
| `GC_ROLE` | `ROLE_ID`, code, libellé, statut | PK; code unique. |
| `GC_PERMISSION` | `PERMISSION_ID`, code, description fonctionnelle | PK; code unique et stable. |
| `GC_USER_ROLE` | `USER_ID`, `ROLE_ID`, dates d'effet, attribué par | PK composite; FK compte/rôle; historique d'attribution conservé. |
| `GC_ROLE_PERMISSION` | `ROLE_ID`, `PERMISSION_ID` | PK composite; FK rôle/permission. |
| `GC_USER_MFA_FACTOR` | `USER_ID`, type de facteur approuvé, secret chiffré ou référence fournisseur, état, dates d'enrôlement | FK compte; requis pour administrateurs et approbateurs; secrets jamais journalisés. |
| `GC_AUDIT_EVENT` | `AUDIT_EVENT_ID`, acteur, action, objet, horodatage, résultat, motif, corrélation, données de changement minimisées | PK; index objet/date, acteur/date; insertion seule pour rôles applicatifs. |
| `GC_API_IDEMPOTENCY` | clé de requête, principal, ressource, empreinte de demande, résultat/référence, date d'expiration | PK composite principal/clé; empêche la création en double après retry. |

## Contraintes et index Oracle

- Clés primaires sur tous les identifiants; clés étrangères sur toutes les relations métier, sans cascade destructive depuis les documents validés.
- `UNIQUE` sur codes tiers/produits/rôles/permissions, identifiants fournisseurs par fournisseur, séries-numéros documentaires et clés d'idempotence.
- `CHECK` sur états admis, montants positifs/nuls selon objet, quantités cohérentes, devise EUR en v1 et relations produit/service-stock.
- Index B-tree sur clés étrangères fréquemment jointes, `PARTY_ID + STATUS + document_date`, `PRODUCT_ID + WAREHOUSE_ID`, références et échéances; index additionnels décidés par plans d'exécution réels.
- Ne pas indexer les colonnes à faible sélectivité seules; mesurer les rapports et recherches soumis à NFR-001 avant d'ajouter des index.
- Le chevauchement des périodes tarifaires, le cumul de crédit, les plafonds de remise, la réservation et les totaux de documents sont des invariants transactionnels vérifiés par packages sous verrou; ils ne reposent pas uniquement sur l'interface.
- Une facture ou un avoir validé est protégé par les privilèges de schéma et par les opérations de package; aucune page APEX ou ressource ORDS n'expose de mise à jour directe.

## Relations principales

- `GC_PARTY` 1:0..1 `GC_CUSTOMER` et 1:0..1 `GC_SUPPLIER`; un tiers peut cumuler les deux rôles sans fusion des soldes.
- `GC_CUSTOMER` 1:N devis, commandes, factures et règlements; `GC_SUPPLIER` 1:N commandes d'achat, factures et règlements.
- `GC_QUOTE` 1:N lignes; devis accepté 0..1 commande client.
- Commandes et lignes d'achat/vente 1:N réceptions/livraisons et lignes; les lignes source permettent les contrôles de reliquat.
- `GC_PRODUCT` 1:N tarifs, mouvements, réservations et lignes documentaires; `GC_WAREHOUSE` 1:N soldes et mouvements.
- Facture client 1:N lignes, avoirs et affectations de règlement; facture fournisseur 1:N lignes et affectations.
- Utilisateur N:N rôles via `GC_USER_ROLE`; rôle N:N permissions via `GC_ROLE_PERMISSION`; chaque opération sensible référence un acteur d'audit.