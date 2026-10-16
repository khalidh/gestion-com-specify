# Adaptateurs

Les adaptateurs traduiront des artefacts source vers des preuves et mappings normalisés; ils ne déploieront rien.

| Adaptateur | État dans le MVP | Entrée requise |
|---|---|---|
| Oracle APEX | Premier adaptateur en lecture seule à réaliser | Export APEX et artefacts Oracle autorisés |
| Oracle Forms existant vers APEX | Non validable ici sans source Forms | Exports Forms, PL/SQL, bibliothèques et dépendances |
| Spécifications vers Oracle Forms | Proposition d'architecture seulement; génération de modules non implémentée | Spécifications et modèle métier approuvés; profil Forms à confirmer |
| SAP ECC Dynpro vers RAP/Fiori | Ultérieur | Sources Dynpro/ABAP et objets associés |
| SAP ABAP legacy vers ABAP Cloud | Ultérieur | Sources ABAP et contraintes de version |
| COBOL vers Java | Ultérieur | Sources COBOL, copybooks et contrats d'exécution |

Les adaptateurs SAP et COBOL ne sont pas créés dans le squelette initial.