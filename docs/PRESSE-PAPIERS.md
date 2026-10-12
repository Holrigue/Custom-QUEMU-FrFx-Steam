# Coller depuis Windows vers la VM

Un vrai presse-papiers bidirectionnel **n'est pas disponible** avec ce build QEMU-Windows :

- **GTK + agent (spice-vdagent)** : l'intégration presse-papiers de GTK est une fonctionnalité expérimentale **désactivée par défaut** à la compilation de QEMU (risque de blocage). Le build weilnetz ne l'a pas → le collage ne fait rien, même avec l'agent actif côté VM.
- **SPICE (`-display spice-app`)** : le serveur SPICE **ne s'initialise pas** sous Windows sur ce build (« Failed to open SPICE sockets »).

## La solution : « Coller dans la VM » (Windows → VM)

À défaut de synchro native, l'outil **tape** le presse-papiers Windows dans la fenêtre active de la VM, via un canal de contrôle local. Sens unique (Windows → VM), ce qui couvre le besoin principal : coller des **commandes / URLs**.

### Sécurité (environnement de travail)
- Le canal est un socket **`127.0.0.1` (loopback uniquement)**, jamais exposé au réseau.
- **Aucune installation, aucun droit admin, aucune modification système, aucun pare-feu** : juste deux processus de l'utilisateur (QEMU + un script) qui communiquent en local.
- Ouvert seulement si on lance via `Jouer-Presse-papiers.cmd` (option `-Control`).

### Utilisation
1. Lancer la VM avec **`Jouer-Presse-papiers.cmd`** (mode bureau GTK + canal de contrôle local).
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
- En **mode jeu** (`Jouer-Jeu.cmd`, SDL), le canal n'est pas ouvert : le collage est un besoin bureau, pas jeu.
