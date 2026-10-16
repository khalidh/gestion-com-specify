# Adaptateur Oracle Forms

Deux flux distincts sont documentés ici; ils ne doivent pas être confondus.

## Oracle Forms existant vers APEX

Ce flux analyse des sources Forms (`.fmb`, `.fmx`, bibliothèques, PL/SQL et dépendances) pour préparer une proposition de modernisation vers APEX. Il reste bloqué pour validation fonctionnelle tant qu'un jeu source représentatif n'est pas fourni et autorisé.

## Spécifications vers une cible Oracle Forms

Le workflow de rétro-spécification accepte `--target oracle-forms`. Il produit une proposition d'architecture fondée sur les sources autorisées du dépôt et conserve les preuves et statuts de la spécification.

Ce profil est une proposition uniquement : il ne génère ni `.fmb`/`.fmx`, ni code PL/SQL, ne modifie aucune source et n'accède à aucune base. Le plan de migration reste bloqué tant que des tâches spécifiques Forms ne sont pas approuvées.

Décisions à confirmer avant d'établir ce plan : version Forms/Reports et correctifs, format de livraison, runtime et hébergement, authentification, rapports, règles d'accès et stratégie de test des modules.

Exécution de l'analyse :

```powershell
python -m orchestrator.reverse_specification --target oracle-forms --run-id forms-design-review
```

Les brouillons sont écrits sous `generated/runs/`; leur promotion et toute implémentation nécessitent une revue et les approbations applicables.