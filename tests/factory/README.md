# Tests de la Factory

Le répertoire pytest est réservé aux tests du workflow et des adaptateurs. Les premiers tests devront couvrir les exclusions de secrets, la traçabilité des preuves, les statuts d'implémentation et l'absence d'écriture dans les sources.

Les tests initiaux sont dans `test_reverse_specification.py`; ils couvrent l'analyse du dépôt réel, les fixtures synthétiques, les sorties confinées et les cas bloquants.