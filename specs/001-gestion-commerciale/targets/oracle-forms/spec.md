# Addendum de cible : Oracle Forms

**Feature**: Gestion commerciale pour PME ([spécification métier](../../spec.md))  
**Statut**: Cible Oracle Forms approuvée pour planification le 2026-10-16; les décisions de déploiement et l'autorisation d'implémentation restent ouvertes.

## Portée

Cet addendum définit une cible de présentation alternative à APEX. Il réutilise les exigences, règles métier, entités et tests de la spécification parent; il ne crée pas de règles métier concurrentes et ne remplace pas le plan APEX existant. Les écrans Forms appellent les packages PL/SQL autorisés. Aucun accès de mutation direct aux tables n'est permis.

Les versions Oracle Forms/Reports, le runtime, l'hébergement, le format des sources et des exécutables, l'authentification et l'outillage de test restent à fixer dans [profile.yaml](profile.yaml).

## User stories de la cible

Les priorités et critères métier sont ceux de la spécification parent. Les références ci-dessous sont conservées sans renumérotation.

| Cible | Priorité | Écrans de référence | Exigences et tests métier |
|---|---:|---|---|
| US1 Référentiels commerciaux | P1 | Pages 030, 031, 040, 041 | FR-001 à FR-003; TEST-001 à TEST-004 |
| US2 Devis et commandes clients | P1 | Pages 050, 060, 061 | FR-003 à FR-006; TEST-005 à TEST-010 |
| US3 Achats, réceptions et stocks | P1 | Pages 070, 071, 080, 081 | FR-007, FR-008; TEST-011 à TEST-016 |
| US4 Livraisons | P1 | Page 090 | FR-008, FR-009; TEST-018, TEST-019 |
| US5 Factures, avoirs et règlements clients | P1 | Pages 100, 102, 110 | FR-010 à FR-012; TEST-020 à TEST-024 |
| US6 Factures fournisseurs | P2 | Page 101 | FR-007, BR-033, BR-034; TEST-017 |
| US7 Accès et audit | P1 | Pages 001, 120, 121 | FR-013, FR-014; TEST-025 |
| US8 Pilotage | P2 | Pages 010, 020 à 022 | FR-015, FR-017; tests de vérification de la spécification parent |

## Critères d'acceptation de la cible

- Chaque écran de référence est relié à un module Forms, à ses rôles et aux exigences métier qu'il sert.
- Toute action métier appelle un package PL/SQL; les règles, transactions, autorisations et audits ne sont pas dupliqués dans les triggers Forms.
- Les parcours refusés, erreurs compréhensibles en français, navigation clavier, états documentaires et confirmations suivent les contrats d'interaction de [ui-screens.md](../../ui-screens.md).
- Les scénarios TEST-001 à TEST-025 restent la référence pour le comportement métier; les tests d'interface Forms vérifient les interactions et l'appel correct des packages sans remplacer utPLSQL.
- Aucune source Forms ou exécution de compilation ne cible un environnement partagé ou de production avant validation du profil technique et de l'environnement isolé.

## Gates

La validation de cet addendum autorise la préparation du plan. La constitution actuelle impose APEX comme interface; une exception formelle, limitée à cette cible alternative, doit être approuvée et enregistrée avant l'implémentation. Les inconnues du profil technique doivent également être résolues avant la création de modules exécutables.