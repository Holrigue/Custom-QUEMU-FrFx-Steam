# Coller depuis Windows vers la VM

Un vrai presse-papiers bidirectionnel **n'est pas disponible** avec ce build QEMU-Windows :

- **GTK + agent (spice-vdagent)** : l'intégration presse-papiers de GTK est une fonctionnalité expérimentale **désactivée par défaut** à la compilation de QEMU (risque de blocage). Le build weilnetz ne l'a pas → le collage ne fait rien, même avec l'agent actif côté VM.
- **SPICE (`-display spice-app`)** : le serveur SPICE **ne s'initialise pas** sous Windows sur ce build (« Failed to open SPICE sockets »).

## La solution : « Coller dans la VM » (Windows → VM)

À défaut de synchro native, l'outil **tape** le presse-papiers Windows dans la fenêtre active de la VM, via un canal de contrôle local. Sens unique (Windows → VM), ce qui couvre le besoin principal : coller des **commandes / URLs**.

### Sécurité (environnement de travail)
- Le canal est un socket **`127.0.0.1` (loopback uniquement)**, jamais exposé au réseau.
- **Aucune installation, aucun droit admin, aucune modification système, aucun pare-feu** : juste deux processus de l'utilisateur (QEMU + un script) qui communiquent en local.
- Ouvert par les lanceurs **`Jouer.cmd`** et **`Jouer-Jeu.cmd`** (option `-Control`), loopback uniquement.

### Utilisation
1. Lancer la VM : **`Jouer.cmd`** (bureau, recommandé pour coller) ou `Jouer-Jeu.cmd` (jeu). Le canal de contrôle local est actif dans les deux.
2. Dans Windows, **copier** le texte voulu (Ctrl+C).
3. Dans la VM, **cliquer dans le champ cible** (terminal, barre d'adresse…) pour qu'il ait le focus.
4. Lancer **`Coller-dans-VM.cmd`** : le texte est tapé dans la VM.

### Prérequis clavier : US
La frappe suppose la disposition **US** dans la VM (mapping caractère → touche US). Si la VM est en CA/FR, les symboles seront faux.
- Rapide (par session), dans un terminal : `setxkbmap us`.
- Permanent : Settings → Keyboard → Layout → ajouter **English (US)** et le mettre en premier (garder CA en secondaire si besoin de taper du français, bascule via le raccourci de disposition).

### Limites
- **Sens unique** : pas de copie VM → Windows par ce biais.
- Caractères **non-ASCII** (accents é à …) ignorés — rares dans des commandes/URLs.
- Le canal est ouvert aussi en **mode jeu** (`Jouer-Jeu.cmd`), mais coller est surtout un besoin bureau : en SDL plein écran il n'y a pas de champ pratique où coller. Utiliser `Jouer.cmd` pour le presse-papiers.
