# Choix techniques — vérification du 28 septembre 2026

| Projet | Capacité pertinente | Limite pour ce prototype |
|---|---|---|
| [QEMU](https://www.qemu.org/download/) et [documentation](https://www.qemu.org/docs/master/system/invocation.html) | Émulation TCG, accélération WHPX Windows, image disque persistante, NAT utilisateur et périphériques virtuels | Accélération CPU ne garantit pas GPU/décodage vidéo; binaires Windows fournis par un tiers référencé officiellement. Portabilité réelle à tester sur chaque PC. |
| [dockerportable](https://github.com/knockshore/dockerportable) | Idée utile : arborescence autonome, chemins locaux, QEMU et disque Linux portable | Exemple Docker/Alpine, pas une station Steam graphique. Le dépôt consulté ne constitue pas une livraison Remote Play complète. Aucun code repris. |
| [TinyUSB](https://docs.tinyusb.org/en/latest/) | Classes clavier HID et stockage MSC, exemples et prise en charge de nombreux microcontrôleurs | Une pile USB ne fournit pas une mémoire assez grande/rapide pour une VM. Capacité, débit et firmware du montage doivent être mesurés. |
| [Portable-VirtualBox](https://github.com/vboxme/Portable-VirtualBox) | Emballage portable de VirtualBox | Le README évoque des problèmes de NAT et un retour à 7.0.20. Les pilotes hôtes et privilèges restent un enjeu; pas retenu pour garantir un lancement sans installation sur chaque PC. Pas de test VirtualBox effectué. |

Distribution : [Xubuntu 24.04 LTS](https://xubuntu.org/release/24.04/) avec [Steam multiverse](https://packages.ubuntu.com/noble/steam-installer). [Images officielles](https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/). Utilisation prévue : [Steam Remote Play](https://store.steampowered.com/remoteplay).

Version Windows extraite : QEMU 11.1.0, paquet `v11.1.0-12130-ge470268ff4`, installateur `qemu-w64-setup-20260811.exe`. Version sélectionnée disponible chez [Stefan Weil](https://qemu.weilnetz.de/w64/), pas une affirmation que tous les correctifs de QEMU amont y sont inclus. Somme SHA512 vérifiée avant extraction.

## Phase 3 : différée

Stockage FAT32 : [QEMU documente le format VMDK segmenté](https://qemu-project.gitlab.io/qemu/system/images.html). Le prototype emploie `twoGbMaxExtentSparse` pour éviter de reformater le support de test. Conserver tous les segments ensemble.

Aucune injection clavier, aucun firmware, aucun lancement au branchement activé. Condition préalable : phase 1 validée avec streaming utilisable, persistance et arrêt propre.

Comparaison préliminaire seulement : A (stockage + HID sur microcontrôleur unique) concentre les contraintes de débit, capacité et robustesse du stockage; B (hub à une prise avec stockage standard et contrôleur HID distincts) sépare ces fonctions et semble plus fiable. Le choix définitif et la liste de matériel attendent les résultats de phase 1, conformément au mandat. La clé ordinaire reste le premier support.

Après validation : détecter les volumes et chercher un identifiant unique de projet (`STEAM-USB-ID.txt`), exiger une correspondance unique, puis résoudre le lanceur relativement au marqueur. Ne jamais se fier uniquement au nom de volume ou à D:. Interrupteur physique d'armement, délai annulable et fichier de désactivation seront nécessaires. Tenir compte de la disposition du clavier québécois. Aucun contournement d'écran verrouillé, de politique d'entreprise ou d'UAC.
