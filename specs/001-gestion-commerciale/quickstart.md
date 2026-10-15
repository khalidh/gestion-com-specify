# Guide de validation de la conception

Ce guide décrit les gates et commandes prévues pour la future chaîne de validation. Les scripts de test et de déploiement ne sont pas encore créés: ce document n'est pas exécutable avant l'approbation de `spec.md` et l'implémentation des suites prévues.

## Prérequis de l'environnement

- Environnement Oracle Database, APEX et ORDS dont les versions sont approuvées par l'équipe DBA.
- Schéma de test isolé, privilèges minimaux et Liquibase configuré sur le changelog validé.
- utPLSQL installé dans l'environnement de test; Node.js/Playwright configurés pour l'environnement APEX de test.
- Comptes synthétiques par rôle, MFA pour administrateurs/approbateurs et secrets fournis par un coffre de CI, jamais commités dans Git.
- Jeu de données synthétique reproductible; aucune donnée personnelle ou financière de production.

## Ordre de validation prévu

1. Vérifier que l'approbation métier de la spécification, les versions cibles et la revue comptable française sont enregistrées.
2. Appliquer les changesets Liquibase sur une base de test vierge puis sur une base de mise à niveau représentative; vérifier l'historique et les contraintes.
3. Exécuter les suites utPLSQL des packages du module livré. Chaque résultat référence package, BR et scénario TEST associés.
4. Exécuter les scénarios de contrat REST avec identités autorisées/refusées et vérifier payloads, statuts et absence de fuite d'erreur interne.
5. Exécuter les scénarios Playwright APEX en français avec profils commerciaux, stock, comptabilité, administrateur et approbateur.
6. Exécuter les scénarios multi-session de confirmation de commandes/réservations et affectation de paiements; vérifier l'absence de dépassement concurrent.
7. Comparer les résultats aux critères de succès SC-001 à SC-007 et archiver le rapport de release dans CI.

## Commandes prévues après implémentation

Les noms ci-dessous sont des points d'entrée planifiés et devront être créés dans les tâches d'implémentation. Ne pas exécuter avant leur existence et la validation de l'environnement.

```powershell
liquibase --changelog-file=database/changelog/db.changelog-master.yaml validate
liquibase --changelog-file=database/changelog/db.changelog-master.yaml update-sql
sql -L $env:GC_TEST_CONNECT @database/tests/run-utplsql.sql
npx playwright test tests/playwright
```

`GC_TEST_CONNECT` est injecté de manière sécurisée par l'environnement; aucune chaîne de connexion ni mot de passe n'est stocké dans la commande ou le dépôt. L'application doit être déployée sur l'environnement de test avant Playwright.

## Résultats attendus

- Liquibase valide les changesets ordonnés sans divergence; aucun script n'est appliqué deux fois et aucune donnée n'est supprimée implicitement.
- utPLSQL passe tous les tests des BR implémentées; les cas négatifs et les transitions interdites sont vérifiés.
- Playwright passe les parcours indépendants TEST-001 à TEST-025 livrés dans la phase concernée, dont MFA privilégié et permissions refusées.
- Les tests de concurrence n'autorisent ni dépassement du plafond client, ni stock négatif, ni affectation supérieure au solde dû.
- Les erreurs présentées sont en français, portent un code stable et n'exposent ni détail Oracle ni données hors rôle.
- Les gates réglementaires, de restauration, de performance et de sécurité sont approuvés avant la mise en service.