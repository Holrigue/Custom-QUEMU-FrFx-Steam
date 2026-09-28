# Suivi hebdomadaire

Premier scan GitHub exécuté avec succès le 28 septembre 2026, sans changement de versions. La création automatique de PR est actuellement désactivée dans les paramètres du dépôt. Le workflow peut actualiser sa branche dédiée; s'il ne peut pas ouvrir la PR, il émet un avertissement. Une PR peut alors être ouverte manuellement. Aucun paramètre de permissions n'a été élargi lors de la publication.

Chaque lundi à 10 h 23 UTC, ou à la demande, `upstream-versions.yml` lit Firefox stable, le build du client Steam Linux et la version du lanceur Debian Steam. Sources HTTPS consignées dans `versions/upstream.json`.

En cas de changement, la branche `automation/upstream-versions` et une pull request sont mises à jour. Pas de fusion automatique ni de commit sans changement. Conflits : échec sans push forcé. Autoriser Actions à créer des PR dans les paramètres du dépôt; aucun jeton personnel requis.

Le scan ne reconstruit pas de VM et n'installe rien sur une clé. Ce n'est ni un audit de sécurité ni un test de compatibilité. Steam se met à jour lui-même; Firefox installé par le script se met à jour via APT.

GitHub peut retarder les exécutions ou désactiver les planifications de dépôts publics inactifs après 60 jours : https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule .
