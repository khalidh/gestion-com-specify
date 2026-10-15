# Exports Oracle APEX

Les exports APEX versionnés sont conservés dans `apex/exports/`, séparés par application et livrable.

## Prototype initial

- Export SQL : `gestion-commerciale-v1/f100.sql`.
- Application APEX : ID `100`, nom `Gestion commerciale`, APEX `24.2`.
- Schéma d'analyse : `GC_APP` dans le workspace `GESTION_COMMERCIALE`.
- La page `Clients` lit `GC_APP.VW_GC_CUSTOMER_LIST`; appliquer d'abord `database/changelog/changesets/001_gc_customer_foundation.sql`.
- La page d'accueil garde des indicateurs commerciaux statiques de démonstration; elle ne prétend pas calculer les ventes ou les stocks depuis Oracle.
- Pour importer : ouvrir App Builder dans le workspace cible, choisir **Import**, téléverser `f100.sql`, puis installer l'application.

## Règles de contribution

- Exporter l'application avec l'outil supporté par la version APEX approuvée; ne pas éditer manuellement les identifiants générés sans justification.
- Chaque changement d'écran est relu et associé à une story, des exigences FR/NFR et aux règles BR correspondantes.
- Les validations APEX servent l'expérience utilisateur; chaque mutation appelle le package métier qui revalide autorisation et invariants.
- Ne pas placer de secret, valeur de production ou identifiant personnel réel dans un export.
- Tester les parcours dans une instance isolée avant de promouvoir un export; documenter dépendances et ordre de livraison.
- Un export de prototype ne remplace pas les migrations de schéma, packages métier et validations prévus par le plan.
