# Validation de la fondation Oracle

`validate-foundation.ps1` exécute T014 : il valide le changelog, applique les changesets, compile les packages de fondation et vérifie les grants. C'est une opération avec effets de bord, réservée à un PDB de test jetable. Ne l'exécutez jamais sur `ORCLPDB`, sur la base APEX locale existante ou sur une base partagée/de production.

## Prérequis

- Un PDB jetable dont le nom commence par `GC_TEST_`, contenant le schéma propriétaire `GC_APP`.
- Le schéma `GC_APP` doit être vierge de toute table; le préflight refuse un schéma préexistant, notamment l'instance locale dont le changeset Clients a été appliqué hors Liquibase.
- Deux schémas runtime distincts, nommés avec le préfixe `GC_TEST_`, pour APEX et ORDS; ils ne doivent pas posséder les tables métier.
- `liquibase` et `sqlplus` accessibles dans `PATH`.
- Le fichier `database/admin/tns-test/tnsnames.ora`, qui ne contient que l'alias local `GC_TEST_PDB` vers `127.0.0.1:1521/gc_test_pdb`.
- Le même alias TNS configuré comme URL JDBC Liquibase (`jdbc:oracle:thin:@<alias>`).
- Le compte Liquibase `GC_APP`; si `.env.test.local` contient `GC_TEST_GC_APP_PASSWORD`, le script l'utilise pour Liquibase et SQL*Plus sans l'afficher. Sinon, il demande le mot de passe dans une invite masquée. Le secret est retiré de l'environnement à la fin.

## Exécution explicite

Après confirmation manuelle que l'alias pointe vers le PDB jetable, définissez les variables non secrètes dans PowerShell :

```powershell
$env:GC_TEST_ISOLATED = 'YES'
$env:GC_TEST_TNS_ALIAS = 'GC_TEST_<alias>'
$env:GC_TEST_PDB_NAME = 'GC_TEST_<pdb>'
$env:GC_TEST_APEX_RUNTIME_SCHEMA = 'GC_TEST_<apex_schema>'
$env:GC_TEST_ORDS_RUNTIME_SCHEMA = 'GC_TEST_<ords_schema>'
$env:TNS_ADMIN = (Resolve-Path '.\database\admin\tns-test').Path
$env:LIQUIBASE_COMMAND_URL = "jdbc:oracle:thin:@$env:GC_TEST_TNS_ALIAS"
```

Ne définissez pas de variable de mot de passe. Le script la demande de manière masquée, effectue le préflight SQL*Plus, puis `liquibase validate/update` sur la même cible.

```powershell
.\tests\database\validate-foundation.ps1 -Apply
```

Sans `-Apply`, le script s'arrête. Avant `liquibase update`, il vérifie par SQL*Plus l'utilisateur `GC_APP`, le nom réel du PDB, le fait que `GC_APP` est vierge, les deux schémas runtime et l'alias de test. En cas d'échec du préflight, aucun changeset n'est appliqué. Le script ne synchronise pas l'historique Liquibase de l'instance locale existante.