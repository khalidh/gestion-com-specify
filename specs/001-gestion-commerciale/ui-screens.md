# Écrans Oracle APEX

Les pages APEX sont regroupées par module. Les recherches et rapports lisent des vues autorisées; toute commande modifiant l'état appelle le package métier correspondant. Les validations de page améliorent l'expérience mais ne remplacent jamais les contrôles PL/SQL.

| Page | Écran / usage | Rôles | Actions et règles visibles |
|---|---|---|---|
| 001 | Connexion locale | Tous | Authentification individuelle; étape MFA obligatoire si rôle administrateur/approbateur; erreurs génériques ne révélant pas l'existence d'un compte. |
| 010 | Accueil et navigation | Tous | Menus adaptés aux permissions; alertes liées aux échéances et approbations accessibles. |
| 020 | Tableau de bord commercial | Dirigeant, commercial autorisé | Ventes, devis à relancer, commandes et livraisons en retard; filtres période/statut; totaux fondés sur documents validés. |
| 021 | Tableau de bord stock/achats | Dirigeant, acheteur, stock | Disponibles par dépôt, seuils, reliquats de réception; drill-down soumis aux permissions. |
| 022 | Tableau de bord financier | Dirigeant, comptable | Créances, dettes, échéances et règlements; accès restreint aux montants financiers. |
| 030 | Liste et fiche client | Commercial, comptable, administrateur | Recherche, coordonnées, adresse de facturation, statut, limite de crédit et historique. |
| 031 | Liste et fiche fournisseur | Acheteur, comptable, administrateur | Coordonnées, conditions, commandes, factures et règlements fournisseur. |
| 040 | Catalogue produits | Commercial, acheteur, stock, administrateur | Recherche, type article/service, unité, taxe, statut et règles de stock. |
| 041 | Tarifs et remises | Commercial autorisé, administrateur | Tarifs EUR datés et paliers; contrôle de chevauchement; affichage de la limite de remise du rôle. |
| 050 | Liste et éditeur de devis | Commercial | Lignes, validité, remise, taxe, aperçu imprimable; actions Émettre, Accepter, Refuser, Convertir selon état. |
| 060 | Liste et fiche commande client | Commercial, approbateur | Exposition crédit, disponible, réservations et reliquat; Confirmer, Demander dérogation, Réviser, Annuler selon permissions. |
| 061 | Boîte d'approbation | Approbateur, administrateur autorisé | Décisions motivées sur dérogations, achats ou remises; séparation demandeur/approbateur. |
| 070 | Commandes d'achat | Acheteur, approbateur | Création, soumission, approbation, transmission, état de réception et reliquat. |
| 071 | Réceptions fournisseurs | Gestionnaire de stock, acheteur | Réception partielle, quantité refusée, écart, dépôt, validation autorisée et mouvements créés. |
| 080 | Consultation stock | Gestionnaire de stock, acheteur, commercial en lecture | Physique, réservé, disponible, sécurité et historique de mouvements par dépôt/produit. |
| 081 | Inventaire et transferts | Gestionnaire de stock autorisé | Comptage, ajustement motivé, transferts dépôt à dépôt et suivi de validation. |
| 090 | Préparation et suivi livraisons | Gestionnaire logistique | Quantités préparées, réservées, expédiées et reliquat; confirmation atomique et preuve de livraison à définir. |
| 100 | Factures clients | Comptable | Prévisualisation, mentions françaises à date, validation et consultation; aucune action modifier/supprimer après validation. |
| 101 | Factures fournisseurs | Comptable, acheteur | Rapprochement commande/réception, écarts, approbation et échéance. |
| 102 | Retours et avoirs | Comptable, gestionnaire stock | Réception et état des retours, décision de remise en stock, préparation/validation d'avoir lié. |
| 110 | Règlements et affectations | Comptable | Saisie EUR, affectations partielles, reliquat non affecté et soldes avant/après. |
| 120 | Comptes et rôles | Administrateur habilité | Création/désactivation comptes locaux, attribution/révocation de rôles, enrôlement MFA privilégié. |
| 121 | Audit | Auditeur, administrateur sécurité | Recherche en lecture seule par acteur, période, document, action et résultat; aucune mutation des événements. |
| 130 | Paramètres fonctionnels | Administrateur habilité | Seuils, séries documentaires, termes de paiement, dépôts et paramètres dont les règles sont validées. |

## Contrats d'interaction

- Chaque action de validation demande une confirmation explicite, affiche les objets et quantités/montants impactés et présente le résultat de la transaction.
- Un refus indique la règle métier concernée (identifiant BR), le motif compréhensible et l'action corrective ou le rôle requis; aucun détail Oracle interne n'est affiché.
- Les formulaires de document distinguent brouillon, document soumis et document validé; les champs d'une facture validée sont en lecture seule.
- L'interface est en français, navigable au clavier et expose erreurs, états vides et chargements sans perdre une saisie non validée.
- Les pages d'administration, MFA et audit sont masquées par permission et recontrôlées côté package, pas uniquement par visibilité APEX.

## Vues de lecture

Les pages de recherche utilisent des vues explicitement autorisées: vue des tiers actifs, catalogue et tarifs applicables, disponibilité par dépôt, reliquats de commande, échéances et agrégats de tableau de bord. Une vue ne contient que les colonnes nécessaires à son rôle; aucune vue ne permet de modifier directement une facture validée ou un mouvement d'audit.