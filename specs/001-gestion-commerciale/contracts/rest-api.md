# Contrats REST ORDS

## Principes

- Préfixe versionné proposé: `/api/v1`; les URI représentent des ressources, les transitions métier sont des actions explicites.
- Tous les appels sont authentifiés et autorisés selon les permissions métier. Aucune ressource anonyme ni AutoREST direct sur les tables de gestion.
- APEX et ORDS appellent les mêmes packages; ORDS valide le format, l'identité, la pagination et le contrat, jamais les règles métier.
- Les comptes humains sont locaux à l'application; les intégrations machine éventuelles utilisent un principal technique dédié et des permissions restreintes, après validation de sécurité.
- Les appels de mutation acceptent une clé d'idempotence lorsque le retry pourrait créer un document ou un règlement en double.

## Ressources initiales

| Méthode et ressource | Package responsable | Permission indicative | Résultat métier |
|---|---|---|---|
| `GET /parties?role=&status=&q=` | `PKG_GC_PARTY` | `PARTY_READ` | Liste paginée de tiers accessibles. |
| `POST /customers` | `PKG_GC_PARTY` | `CUSTOMER_WRITE` | Création d'un client. |
| `POST /suppliers` | `PKG_GC_PARTY` | `SUPPLIER_WRITE` | Création d'un fournisseur. |
| `GET /products?status=&q=` | `PKG_GC_CATALOG` | `PRODUCT_READ` | Catalogue paginé. |
| `POST /products` | `PKG_GC_CATALOG` | `PRODUCT_WRITE` | Création contrôlée d'un produit. |
| `GET /price-lists/{id}/prices?product=&date=&quantity=` | `PKG_GC_PRICING` | `PRICE_READ` | Tarif applicable en EUR. |
| `POST /quotes` | `PKG_GC_QUOTES` | `QUOTE_WRITE` | Création d'un devis brouillon. |
| `POST /quotes/{id}/issue` | `PKG_GC_QUOTES` | `QUOTE_ISSUE` | Émission et gel de la version envoyée. |
| `POST /quotes/{id}/accept` | `PKG_GC_QUOTES` | `QUOTE_ACCEPT` | Acceptation datée du devis courant. |
| `POST /quotes/{id}/convert` | `PKG_GC_SALES_ORDERS` | `ORDER_CREATE` | Conversion unique vers une commande. |
| `POST /sales-orders` | `PKG_GC_SALES_ORDERS` | `ORDER_CREATE` | Création d'une commande brouillon. |
| `POST /sales-orders/{id}/confirm` | `PKG_GC_SALES_ORDERS` | `ORDER_CONFIRM` | Contrôle crédit/stock et confirmation atomique. |
| `POST /sales-orders/{id}/cancel` | `PKG_GC_SALES_ORDERS` | `ORDER_CANCEL` | Annulation des quantités non livrées et libération de réservations. |
| `POST /purchase-orders` | `PKG_GC_PROCUREMENT` | `PURCHASE_WRITE` | Création et soumission d'un achat. |
| `POST /purchase-orders/{id}/approve` | `PKG_GC_PROCUREMENT` | `PURCHASE_APPROVE` | Approbation séparée et motivée. |
| `POST /receipts` | `PKG_GC_PROCUREMENT` | `RECEIPT_WRITE` | Enregistrement d'une réception partielle/totale et mouvement stock. |
| `POST /supplier-invoices` | `PKG_GC_PROCUREMENT` | `SUPPLIER_INVOICE_WRITE` | Saisie d'une facture fournisseur en attente de rapprochement. |
| `POST /supplier-invoices/{id}/validate` | `PKG_GC_PROCUREMENT` | `SUPPLIER_INVOICE_VALIDATE` | Validation après contrôle du doublon, des quantités reçues et des écarts de prix. |
| `GET /inventory/availability?product=&warehouse=` | `PKG_GC_INVENTORY` | `STOCK_READ` | Physique, réservé et disponible par dépôt. |
| `POST /inventory/transfers` | `PKG_GC_INVENTORY` | `STOCK_TRANSFER` | Transfert atomique entre dépôts. |
| `POST /inventory/adjustments` | `PKG_GC_INVENTORY` | `STOCK_ADJUST` | Ajustement motivé et audité. |
| `POST /deliveries` | `PKG_GC_DELIVERY` | `DELIVERY_WRITE` | Préparation liée à une commande confirmée. |
| `POST /deliveries/{id}/dispatch` | `PKG_GC_DELIVERY` | `DELIVERY_DISPATCH` | Expédition, sortie de stock et évolution de reliquat. |
| `POST /customer-invoices` | `PKG_GC_BILLING` | `INVOICE_DRAFT` | Préparation de facture sur quantités facturables. |
| `POST /customer-invoices/{id}/validate` | `PKG_GC_BILLING` | `INVOICE_VALIDATE` | Vérification française, référence unique et gel du document. |
| `POST /credit-notes` | `PKG_GC_BILLING` | `CREDIT_NOTE_CREATE` | Préparation d'un avoir lié à une facture. |
| `POST /payments` | `PKG_GC_PAYMENTS` | `PAYMENT_WRITE` | Saisie d'un paiement EUR. |
| `POST /payments/{id}/allocations` | `PKG_GC_PAYMENTS` | `PAYMENT_ALLOCATE` | Affectation partielle sous plafond de solde. |
| `GET /dashboards/{name}?from=&to=` | `PKG_GC_REPORTING` | Permission de tableau de bord | Agrégats filtrés par période et droits. |
| `GET /audit-events?actor=&object=&from=&to=` | `PKG_GC_AUDIT` | `AUDIT_READ` | Consultation paginée en lecture seule. |
| `POST /users`, `PUT /users/{id}/roles` | `PKG_GC_SECURITY` | `USER_ADMIN` | Administration des comptes/roles avec audit et MFA si rôle privilégié. |

Les routes sont une proposition de contrat à valider en conception d'API; elles ne sont pas encore publiées ni implémentées.

## Enveloppe et erreurs

- Réponse réussie: identifiant de corrélation, ressource et état résultant; listes avec données, filtres et curseur/page explicites.
- Erreur fonctionnelle: code stable (`GC-CREDIT-LIMIT`, `GC-STOCK-UNAVAILABLE`, `GC-INVALID-STATE`, etc.), message français, référence BR, champ/document concerné et action attendue.
- Correspondance HTTP: 400 format invalide; 401 non authentifié; 403 permission absente; 404 ressource non visible/inexistante; 409 conflit d'état, crédit, stock, idempotence ou version; 422 données métier invalides; 500 erreur inattendue avec identifiant de corrélation uniquement.
- Aucune réponse ne divulgue SQL, stack trace, secret, identifiant interne d'un autre utilisateur ou donnée hors périmètre.
- Les mutations transmettent l'acteur issu du contexte authentifié; une valeur `user_id` fournie librement par le client ne peut jamais servir à accorder une permission.
- Les contrats fixent pagination, taille maximale de page, filtres, formats de date/heure, montants EUR, compatibilité et politique de dépréciation avant leur publication.

## Contrats sensibles

- Confirmation commande, expédition, validation de facture, création d'avoir et affectation paiement sont des commandes idempotentes et exécutées dans une seule transaction.
- Les opérations d'approbation exigent un approbateur autorisé distinct du demandeur lorsque la séparation des tâches s'applique.
- Les ressources de lecture vérifient aussi les droits; masquer une page APEX ne remplace pas l'autorisation côté ORDS/package.
- La réception/émission des factures électroniques françaises est un contrat externe à définir après la revue réglementaire; aucune plateforme ni payload fiscal tiers n'est supposé dans cette version de conception.