# Plan d'implémentation : cible Oracle Forms

**Feature**: `001-gestion-commerciale` / profil `oracle-forms`  
**Date**: 2026-10-16  
**Spécification cible**: [spec.md](spec.md)  
**Spécification métier**: [../../spec.md](../../spec.md)  
**Profil**: [profile.yaml](profile.yaml)

**Statut**: plan de conception pour revue. L'utilisateur a approuvé la direction Oracle Forms pour poursuivre la planification. Cette approbation ne fixe pas les versions techniques, ne modifie pas la constitution et n'autorise pas l'implémentation.

## Résumé

Ajouter une présentation Oracle Forms alternative aux parcours métier spécifiés. Les packages PL/SQL restent l'autorité métier, le modèle de données existant reste partagé et la cible APEX reste intacte. Les modules Forms couvriront progressivement les écrans de référence; ils ne porteront ni règles métier concurrentes ni DML direct sur les tables.

## Contexte technique

**Langage/version**: PL/SQL et Oracle Forms; versions et niveaux de correctif `NEEDS CLARIFICATION`.  
**Dépendances principales**: Oracle Database, Forms Builder/Compiler et runtime compatibles, packages PL/SQL existants ou approuvés. ORDS n'est pas une dépendance présumée pour l'interface Forms.  
**Stockage**: modèle conceptuel [data-model.yaml](../../data-model.yaml); schéma physique partiellement présent et non complet.  
**Tests**: utPLSQL pour les règles et transactions; tests d'interface Forms et leur outillage `NEEDS CLARIFICATION`; aucune hypothèse Playwright pour l'interface native Forms.  
**Plateforme cible**: `NEEDS CLARIFICATION` (runtime, topologie, accès bureau et exploitation).  
**Type**: application Oracle Forms modulaire s'appuyant sur services PL/SQL.  
**Objectifs**: conserver NFR-001 à NFR-010 de la spécification parent; confirmer les seuils sous le runtime choisi.  
**Contraintes**: France, EUR, une entité juridique, moindre privilège, MFA pour administrateurs et approbateurs, audit append-only et messages français. Aucun déploiement ni changement de base dans ce plan.  
**Périmètre**: huit user stories de l'addendum; les données de démonstration du prototype ne sont pas une source de règles.

### Décisions encore requises

- Version Forms/Reports, patch set et compatibilité exacte avec la version Oracle Database.
- Runtime, mode de publication, topologie d'hébergement et formats source/compilé à versionner.
- Propagation de l'identité Forms vers `PKG_GC_SECURITY`, politique de session et déclenchement MFA.
- Choix entre Forms/Reports et un autre mécanisme de rapports; aucun choix n'est présumé.
- Outil d'automatisation des parcours Forms, matrice des postes clients et intégration CI.
- Exception formelle à la constitution pour cette cible alternative, limitée au périmètre approuvé.

## Contrôle de constitution

- **Architecture modulaire**: PASS — modules d'écran par parcours, dépendant de contrats PL/SQL documentés.
- **Métier séparé de la présentation**: PASS — les packages PL/SQL restent propriétaires des validations, transitions et transactions.
- **Oracle APEX et ORDS**: EXCEPTION REQUISE — la constitution impose APEX; Oracle Forms est une cible alternative explicite. L'exception formelle doit être enregistrée avant toute implémentation; ce plan ne modifie pas la constitution.
- **Tests et traçabilité**: PASS sous réserve — réutiliser TEST-001 à TEST-025 et BR-001 à BR-050; préciser le harnais UI Forms après décision runtime.
- **Sécurité et audit**: GATE — les modules doivent appeler les contrôles centralisés et démontrer la propagation d'identité avant tout accès métier.
- **Documentation française**: PASS.
- **Gates avant implémentation**: BLOQUÉ — profil technique et exception formelle non complets; test sur environnement Oracle isolé requis.

## Architecture et structure proposées

```text
specs/001-gestion-commerciale/targets/oracle-forms/
  profile.yaml
  spec.md
  plan.md
  tasks.md
forms/
  modules/       # modules source, format à confirmer après choix de version
  menus/         # menus Forms si retenus
  libraries/     # bibliothèques partagées si retenues
tests/forms/     # parcours UI selon le runtime et le harnais approuvés
database/        # schéma et packages partagés; évolution dans le plan commun
```

Les fichiers compilés, les extensions exactes, les rapports et les scripts de publication restent à décider. La cible Forms ne crée pas de copie de `database/`, `apex/` ou `ords/`.

## Découpage de réalisation

1. **Profil et fondations**: fermer les décisions techniques, enregistrer l'exception constitutionnelle, confirmer l'accès aux packages sur une base isolée, établir compilation et tests UI.
2. **Accès et audit (US7)**: intégrer identité, rôles, MFA et consultation d'audit avant d'exposer les opérations métier.
3. **Référentiels (US1, MVP Forms)**: clients, fournisseurs, catalogue et tarifs; validation selon TEST-001 à TEST-004.
4. **Ventes (US2)**: devis, commandes et approbations; TEST-005 à TEST-010.
5. **Achats et stocks (US3, US6)**: achats, réceptions, disponibilité et factures fournisseurs; TEST-011 à TEST-017.
6. **Livraisons (US4)**: préparation, expédition et reliquats; TEST-018 et TEST-019.
7. **Facturation et règlements (US5)**: factures, avoirs, retours et paiements; TEST-020 à TEST-024.
8. **Pilotage (US8)**: tableaux de bord issus de vues/packages autorisés; filtrage et droits selon FR-015/FR-017.
9. **Durcissement**: performance, compatibilité poste, restauration, audit, documentation et revue de mise en service.

Chaque tranche réutilise les règles BR et services SQL/PLSQL approuvés; elle est testée avant la suivante. Les tâches Forms ne remplacent pas les tâches communes de schéma/packages du plan parent.

## Structure décisionnelle et portes

Le profil Forms est ajouté sans remplacer APEX. Avant la première tâche d'implémentation, compléter [profile.yaml](profile.yaml), faire approuver l'exception constitutionnelle, valider la spécification cible, puis vérifier en environnement isolé les grants, packages et dépendances. L'approbation actuelle porte sur la planification uniquement.
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
