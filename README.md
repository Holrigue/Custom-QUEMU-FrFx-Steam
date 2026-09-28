# Custom QEMU · Firefox · Steam USB

**Client Steam Remote Play Linux dans une fenêtre Windows 11**, transportable sur une clé USB ordinaire. Le PC de jeu à la maison exécute les jeux; le PC local exécute QEMU, Linux et le décodage du flux.

**v0.1.0 — prototype expérimental.** Un premier essai Remote Play a été rapporté comme très fluide par l'utilisateur. Ce n'est pas une garantie de FPS ou de compatibilité sur tous les PC. [Tests et limites](docs/TESTS.md).

## Télécharger

Télécharger `SteamUSB-v0.1.0-kit.zip` depuis les [Releases](https://github.com/Holrigue/Custom-QUEMU-FrFx-Steam/releases), puis extraire dans `SteamUSB` sur le support. `SHA256SUMS` contient les empreintes des archives.

**Cette release est un kit de scripts et de documentation. Elle ne contient pas QEMU, l'ISO, un disque Linux préinstallé ou les binaires Firefox/Steam.** La préparation ci-dessous les installe une seule fois; applications et réglages persistent ensuite. Une image neutre préinstallée reste à construire et tester séparément. Aucune VM personnelle ni session Steam n'est publiée. [Préinstallation](docs/PREINSTALLATION.md).

## Prérequis

- Windows 11 x64 Intel/AMD; ARM non pris en charge ici.
- Environ 5–6 Gio de RAM disponibles (VM : 4 Gio, 4 vCPU).
- Clé rapide; essai réalisé sur clé ordinaire 16 Go, capacité serrée. Aucun jeu installé localement.
- Internet; PC de jeu allumé avec Steam Remote Play activé.
- WHPX recommandé si Windows Hypervisor Platform et la virtualisation sont déjà disponibles. Le repli TCG peut être trop lent pour jouer. Aucune activation Windows ni installation de pilote automatique.

## 1. Préparer la clé

Ne pas utiliser Rufus : Windows lance la VM depuis des fichiers ordinaires. Aucun formatage requis.

1. Extraire le kit dans `SteamUSB`.
2. Télécharger `qemu-w64-setup-20260811.exe` et son `.sha512` chez [le distributeur Windows référencé par QEMU](https://qemu.weilnetz.de/w64/). Vérifier avec `Get-FileHash -Algorithm SHA512`. Extraire l'installateur avec 7-Zip **sans l'exécuter**, puis placer son contenu complet dans `runtime/qemu` : EXE, DLL, BIOS et données. Version testée : QEMU 11.1.0 (`v11.1.0-12130-ge470268ff4`).
3. Télécharger `xubuntu-24.04.5-minimal-amd64.iso` et `SHA256SUMS` depuis les [images officielles](https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/). Vérifier SHA256 puis placer l'image dans `iso/`. Hash testé : `9d47f975696ce496b8be882b6d7cc9079c1ea89fb625ac2c86caa63a4f180033`.
4. Lancer `Diagnostic.cmd`, puis `Installer-Linux.cmd`.

```text
SteamUSB/
  Jouer.cmd                démarrage normal sans ISO
  Installer-Linux.cmd       installation initiale
  Tester-Linux.cmd          essai NON persistant
  Diagnostic.cmd
  config/settings.json
  scripts/Launch.ps1
  linux/                   scripts Firefox et Steam
  runtime/qemu/            à ajouter
  iso/                     à ajouter
  vm/                      créé par le lanceur
  logs/                    journaux locaux
```

Xubuntu 24.04 LTS Minimal : Xfce léger, base Ubuntu et bibliothèques Steam i386. Support Xubuntu jusqu'en avril 2027; prévoir une migration. Le navigateur doit être installé séparément.

## 2. Installer Linux une seule fois

1. Ouvrir **Install Xubuntu Minimal** dans le bureau de la VM.
2. Choisir **Interactive installation**.
3. Choisir **Erase disk and install Xubuntu** uniquement pour le **disque virtuel 10 Gio (~10,7 Go), généralement `/dev/vda`**. Aucun disque physique Windows n'est exposé par le lanceur. Si la cible diffère, arrêter et vérifier.
4. Créer son compte et mot de passe directement dans l'interface.
5. À la fin, éteindre Linux, puis lancer **Jouer.cmd**. Ne plus utiliser le mode installation ou essai pour jouer.

Le VMDK est segmenté pour FAT32 : conserver `linux.vmdk` et **tous** les `linux-s*.vmdk` ensemble. Les chemins sont relatifs; la lettre du support peut changer.

Sur 16 Go, QEMU (~1,2 Go), l'ISO (~3 Go temporaire) et le disque virtuel (jusqu'à 10 Gio) sont serrés. Après installation réussie et extinction, conserver l'ISO sur le PC puis la retirer de la clé. Garder une marge sur le support et vérifier aussi `df -h /` dans Linux. Ne pas déplacer de disque actif ni l'exécuter dans un dossier synchronisé par le cloud.

## 3. Installer Firefox et Steam

Dans le terminal du **Linux installé**, télécharger les scripts (aucun navigateur nécessaire) :

```bash
mkdir -p ~/steam-usb-setup
cd ~/steam-usb-setup
wget https://github.com/Holrigue/Custom-QUEMU-FrFx-Steam/releases/download/v0.1.0/SteamUSB-v0.1.0-linux.tar.gz
wget https://github.com/Holrigue/Custom-QUEMU-FrFx-Steam/releases/download/v0.1.0/SHA256SUMS
grep '  SteamUSB-v0.1.0-linux.tar.gz$' SHA256SUMS | sha256sum -c -
```

Continuer uniquement si la vérification affiche **OK** :

```bash
tar -xzf SteamUSB-v0.1.0-linux.tar.gz
bash linux/prepare-persistent.sh
```

Le script refuse le live, demande sudo, prépare les locales fr_CA/en_US, installe Firefox depuis le dépôt Mozilla avec contrôle de l'empreinte de clé, active i386/multiverse et installe Steam avec ses dépendances. Il définit Firefox comme navigateur par défaut et Steam au démarrage de la session Linux. Steam télécharge sa mise à jour initiale au premier lancement; se connecter et saisir Steam Guard uniquement dans son interface.

Les trois scripts `linux/` peuvent aussi être transférés ensemble dans la VM. Le partage du presse-papiers Windows/Linux n'est pas configuré. L'ouverture automatique de session Linux reste un choix de l'utilisateur, pas une fonction du lanceur Windows.

## 4. Jouer et arrêter

Activer Remote Play sur le PC hôte. Dans la VM, utiliser le même compte et choisir **Streamer** depuis le PC distant. Ne pas télécharger les jeux dans la VM.

Point de départ proposé : **720p, 60 i/s, H.264, 10 Mbit/s**, avec statistiques détaillées dans les options avancées Remote Play. Comparer réseau, décodage et fluidité. Tester 1080p/60 et 15–20 Mbit/s seulement si les mesures le permettent. Le profil VGA n'expose pas de décodage GPU matériel.

Souris par défaut **relative** : **Ctrl+Alt+G** capture/libère les entrées dans QEMU GTK. Ce changement vise une caméra trop rapide en jeu; efficacité encore à confirmer. [Détails et retour au mode absolu](docs/SOURIS.md).

Après préparation, éteindre Linux, attendre la fermeture de QEMU, relancer Jouer.cmd et vérifier applications/réglages/streaming. Pour retirer : éteindre Linux, attendre QEMU fermé, éjecter dans Windows. **Aucune protection contre l'arrachement accidentel.**

## Dépannage et limites

- **WHPX absent :** vérifier manuellement virtualisation UEFI, Windows Hypervisor Platform et redémarrage. `profile` accepte `auto`, `whpx` ou `tcg` dans `config/settings.json`.
- **Dépendances Steam :** fermer Synaptic, puis `sudo dpkg --add-architecture i386`, `sudo add-apt-repository -y multiverse`, `sudo apt update`, `sudo apt install steam-installer`. Arrêter si la mise à jour des dépôts échoue. Notre script réalise ces étapes.
- **Écran noir après installation :** blocage observé au restart de l'installateur. Privilégier extinction puis Jouer.cmd sans ISO. Ctrl+Alt+2 ouvre le moniteur QEMU; `system_powerdown` demande l'arrêt propre. `quit` est un dernier recours non propre. Ctrl+Alt+1 revient à l'affichage.
- **Manette :** transmission automatique depuis Windows non implémentée ni validée.
- **Réseau :** NAT utilisateur sans TAP; découverte LAN par diffusion possiblement limitée. Aucun port entrant Windows ouvert par les scripts.
- **Autolancement au branchement :** non inclus. Une clé de stockage seule ne lance pas automatiquement le programme; intégration montre stockage/clavier seulement envisagée.
- **Données personnelles :** ne jamais publier sa VM, ses sessions, ni des captures/journaux contenant des comptes.

## Suivi des versions

Le [workflow](.github/workflows/upstream-versions.yml) lit les versions officielles Firefox/Steam chaque lundi à **10 h 23 UTC**, actualise `versions/upstream.json` et propose une PR en cas de changement. Pas de fusion automatique, de reconstruction d'image ou de mise à jour automatique des VM. [Détails](docs/GITHUB.md).

Tests du scanner : `python -m unittest discover -s tests`. Scan manuel : `python scripts/scan-upstream.py`.

Projet indépendant, sans affiliation à Valve, Mozilla, Canonical ou QEMU. [Projets examinés et choix techniques](docs/RECHERCHE.md).
