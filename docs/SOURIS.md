# Essai souris relative pour Steam Remote Play

Symptôme rapporté : bureau normal mais caméra beaucoup trop rapide en jeu. Hypothèse : conversion du périphérique absolu USB tablet à travers QEMU/Steam. Cause non confirmée tant que le même jeu n'a pas été retesté.

`config/settings.json` utilise maintenant `"mouseMode": "relative"` : QEMU présente `usb-mouse` plutôt que `usb-tablet`. Ne pas modifier la sensibilité Windows/Linux/jeu pendant le premier essai, pour isoler ce changement.

1. Éteindre Linux depuis son menu, attendre la fermeture de QEMU.
2. Relancer `Jouer.cmd` sur la clé. Un simple redémarrage interne Linux ne change pas les périphériques QEMU.
3. Cliquer dans l'affichage de la VM; utiliser **Ctrl+Alt+G** pour capturer les entrées si nécessaire (menu View > Grab Input).
4. Essayer le même jeu via Remote Play et comparer rotations lentes, rapides et mouvements continus.
5. **Ctrl+Alt+G** libère la souris et le clavier pour revenir à Windows.

Retour arrière : remplacer `"relative"` par `"absolute"` dans `mouseMode`, éteindre Linux puis relancer `Jouer.cmd`. Le bureau retrouvera le pointeur absolu intégré. Cette modification ne change pas le disque Linux ni les réglages Steam.

Sources : https://www.qemu.org/docs/master/system/devices/usb.html et https://www.qemu.org/docs/master/system/keys.html .
