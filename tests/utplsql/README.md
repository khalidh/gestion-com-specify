# Conventions des suites utPLSQL

Les tests de packages métier sont organisés par module sous `tests/utplsql/`. Le runner de validation prévu est `database/tests/run-utplsql.sql`; il sera créé avec les premières suites, après validation de l'environnement Oracle isolé.

## Organisation d'une suite

- Nommer la suite d'après le package et le domaine; séparer fixtures, assertions et helpers communs.
- Couvrir le cas nominal, les frontières, les refus d'autorisation et les transitions d'état invalides.
- Lier chaque test à une exigence FR/NFR, une règle BR et un identifiant `TEST-NNN` de `specs/001-gestion-commerciale/spec.md`.
- Utiliser uniquement des données synthétiques; préparer et nettoyer les données de façon déterministe sans toucher aux données partagées ou de production.
- Le helper `support/gc_test_data.sql` crée uniquement les comptes synthétiques `UT_*`; leurs authentifiants APEX restent des variables d'environnement locales et ne sont jamais inclus dans le dépôt.
- Tester les commits/rollbacks à la frontière transactionnelle; les packages métier ne possèdent pas la décision de commit.
- Ajouter des tests multi-session pour crédit, réservation de stock, numérotation et affectation de paiements avant les livraisons concernées.
- Ne pas journaliser de secrets ou d'informations personnelles réelles.

## Conditions d'exécution

Exécuter les suites uniquement dans un schéma Oracle de test avec la version utPLSQL approuvée. Consigner le résultat, les suites, le commit et la couverture BR dans le rapport CI. Aucun test exécutable ou script SQL n'est créé par T006.
