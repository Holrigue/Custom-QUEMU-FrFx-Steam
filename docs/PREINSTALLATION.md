# Préinstallation : état de la release

Une image Linux neutre peut techniquement contenir Firefox et un lanceur Steam préparé. La v0.1.0 fournit un **kit de préparation**, pas une telle image. Aucun disque personnel n'est exporté : même après suppression de comptes, des données peuvent subsister dans ses blocs.

Le parcours disponible installe Linux puis exécute `linux/prepare-persistent.sh`. Les applications et dépendances sont téléchargées par APT; Steam télécharge son client au premier lancement. Les applications persistent ensuite. Internet est requis.

Une future image devra être construite à neuf, sans compte Steam/Firefox, avec création du compte Linux par le destinataire, gestion des identifiants de machine, inventaire des paquets, sommes de contrôle et tests. Vérifier les conditions de redistribution de tous les composants avant publication.

Mozilla permet certaines redistributions inchangées sous conditions : https://www.mozilla.org/en-US/foundation/trademarks/distribution-policy/ . Un téléchargement Steam ne constitue pas à lui seul une autorisation générale de redistribution; lanceur et client sont distincts : https://repo.steampowered.com/steam/ . Cette release télécharge chez les fournisseurs et ne réhéberge pas leurs binaires.

GitHub Releases exige des fichiers de moins de 2 Gio chacun : https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases . Une VM demanderait des archives découpées et une reconstruction vérifiée; ne pas ajouter les gros disques à Git.
