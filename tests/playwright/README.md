# Tests navigateur Playwright

Les tests Playwright vérifient les parcours APEX et les contrats HTTP ORDS. Ils utilisent uniquement des comptes et données synthétiques.

## Exécution

- Installer les dépendances depuis ce dossier après approbation de l'environnement: `npm ci`.
- Définir `GC_APEX_BASE_URL` vers l'instance de test, puis lancer `npm test`.
- Installer le navigateur Chromium correspondant à la version Playwright dans l'image ou l'agent CI approuvé avant les tests navigateur.
- Ne jamais placer de secret dans les tests, le fichier de configuration ou le dépôt; utiliser les variables sécurisées de CI.
- Les tests associent leurs scénarios aux IDs TEST et BR de la spécification; les états et données sont isolés entre scénarios parallèles.

T005 ne télécharge pas de navigateur et n'installe pas de dépendance.
