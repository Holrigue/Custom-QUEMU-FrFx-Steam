# Essai souris relative pour Steam Remote Play

Symptôme rapporté : bureau normal mais caméra beaucoup trop rapide en jeu. Hypothèse : conversion du périphérique absolu USB tablet à travers QEMU/Steam. Cause non confirmée tant que le même jeu n'a pas été retesté.

`config/settings.json` utilise maintenant `"mouseMode": "relative"` : QEMU présente `usb-mouse` plutôt que `usb-tablet`. Ne pas modifier la sensibilité Windows/Linux/jeu pendant le premier essai, pour isoler ce changement.

1. Éteindre Linux depuis son menu, attendre la fermeture de QEMU.
2. Relancer `Jouer.cmd` sur la clé. Un simple redémarrage interne Linux ne change pas les périphériques QEMU.
3. Cliquer dans l'affichage de la VM; utiliser **Ctrl+Alt+G** pour capturer les entrées si nécessaire (menu View > Grab Input).
4. Essayer le même jeu via Remote Play et comparer rotations lentes, rapides et mouvements continus.
5. **Ctrl+Alt+G** libère la souris et le clavier pour revenir à Windows.

Retour arrière : remplacer `"relative"` par `"absolute"` dans `mouseMode`, éteindre Linux puis relancer `Jouer.cmd`. Le bureau retrouvera le pointeur absolu intégré. Cette modification ne change pas le disque Linux ni les réglages Steam.

## Mode jeu (confirmé) — `Jouer-Jeu.cmd`

Essai réalisé : avec le lancement normal (`Jouer.cmd`, affichage **GTK**), même avec la capture `Ctrl+Alt+G`, la souris **sortait de la fenêtre sur les bords gauche/droite** et passait sur le second moniteur. C'est une limite connue de la capture GTK de QEMU sous Windows en multi-écrans (le `ClipCursor` ne tient pas).

Solution confirmée : lancer avec **`Jouer-Jeu.cmd`** (option `-Gaming` du launcher). Ce mode :

- utilise l'affichage **SDL** (`-display sdl,gl=off`) au lieu de GTK : SDL emploie le *pointer-lock* natif de Windows (mode relatif qui re-centre le curseur en continu), ce qui **confine la souris de façon fiable**, y compris en multi-écrans ;
- démarre en **plein écran** (`-full-screen`) sur le moniteur courant ;
- force la **souris relative** (`usb-mouse`) quelle que soit la valeur de `mouseMode`.

Workflow :

1. Éteindre Linux proprement, attendre la fermeture de QEMU.
2. Lancer **`Jouer-Jeu.cmd`**. Steam démarre tout seul (autostart `steam -silent`).
3. Lancer le jeu en Remote Play, **cliquer dans la fenêtre** pour engager la capture (le curseur disparaît = verrouillé).
4. Viser : la souris reste confinée, même en mouvements rapides sur les côtés.
5. **Ctrl+Alt+G** libère la souris ; **Ctrl+Alt+F** quitte le plein écran.

Résultat rapporté par l'utilisateur : fuite latérale **réglée**, caméra contrôlable. Pour l'usage bureau (navigation Steam, réglages), `Jouer.cmd` (GTK) reste plus pratique car le pointeur s'intègre sans capture.

Reste à ajuster si la caméra semble encore trop rapide : désactiver « Améliorer la précision du pointeur » côté Windows (accélération empilée) et baisser la sensibilité en jeu.

Sources : https://www.qemu.org/docs/master/system/devices/usb.html et https://www.qemu.org/docs/master/system/keys.html .
