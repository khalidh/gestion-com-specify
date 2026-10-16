# Recherche et décisions : cible Oracle Forms

**Statut**: décisions d'architecture logique confirmées pour planification; recherche de compatibilité technique différée jusqu'à l'inventaire de l'environnement cible.

## Décisions retenues

| Sujet | Décision | Justification et provenance |
|---|---|---|
| Cible | Ajouter Oracle Forms comme profil alternatif; conserver APEX et son plan existant. | Accord utilisateur du 2026-10-16; les artefacts APEX ne sont pas remplacés. |
| Frontière métier | Les packages PL/SQL restent l'autorité; Forms n'embarque pas de règles concurrentes ni de DML direct. | Constitution, plan parent et conventions Oracle existantes. |
| Données | Réutiliser le modèle conceptuel et les tables/packages communs; ne pas créer un second modèle Forms. | `specs/001-gestion-commerciale/data-model.yaml`; statut conceptuel à préserver. |
| Traçabilité | Réutiliser FR-001..FR-018, BR-001..BR-050 et TEST-001..TEST-025. | Spécification métier parent; aucune renumérotation des identifiants. |
| Portée d'approbation | Architecture logique et préparation du plan seulement. | L'utilisateur a demandé de considérer la direction approuvée et d'avancer; cela ne fixe pas l'environnement technique. |

## Décisions techniques ouvertes

| Sujet | Statut | Prochaine preuve requise |
|---|---|---|
| Oracle Database, Forms/Reports et patch set | À confirmer | Inventaire et compatibilité approuvés par DBA/exploitation. |
| Runtime, hébergement et publication | À confirmer | Décision d'architecture/exploitation; format de source et de compilation associé. |
| Identité et MFA | À confirmer | Contrat de contexte utilisateur et démonstration de refus par défaut via `PKG_GC_SECURITY`. |
| Reporting | À confirmer | Décision sur Forms/Reports ou autre mécanisme et contrôle d'accès aux agrégats. |
| Automatisation des tests UI | À confirmer | Sélection après choix du runtime; utPLSQL reste obligatoire pour la logique PL/SQL. |
| Exception à la constitution | Requise avant implémentation | Enregistrement formel de l'exception limitée à cette cible Oracle Forms. |

Aucune version ou technologie de déploiement n'est déduite de la machine locale. Aucune recherche externe n'est nécessaire avant d'avoir un profil d'environnement approuvé; les décisions ci-dessus restent donc explicitement ouvertes.