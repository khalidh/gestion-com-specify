# Définitions et contrats ORDS

Les définitions ORDS et contrats versionnés sont conservés dans `ords/definitions/`, organisés par domaine et API. La version ORDS et le mécanisme de déploiement restent soumis à validation DBA.

## Règles de contribution

- Exposer des contrats versionnés sous `/api/v1`; documenter méthodes, paramètres, réponse, erreurs, permissions et idempotence.
- ORDS valide l'enveloppe et délègue la logique métier au package propriétaire; aucune règle métier ne doit être dupliquée dans un handler REST.
- Ne pas activer AutoREST ni exposer directement les tables métier.
- Transmettre l'identité depuis le contexte authentifié; ne jamais faire confiance à un identifiant d'acteur fourni par le corps JSON.
- Garder les comptes techniques et secrets hors du dépôt; documenter leurs permissions minimales dans un coffre d'exploitation.
- Tester les contrats et les refus d'accès en environnement isolé avant publication.
- Aucun endpoint ni fichier d'implémentation ORDS n'est créé par T004.

Le fichier `security.yaml` est un contrat proposé pour l'identité, l'autorisation et les grants minimaux; il ne configure pas ORDS. Le mapping entre le principal ORDS et l'utilisateur applicatif doit être défini et validé avant publication de ressources.
