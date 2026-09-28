# Résultats observés — 2026-09-28

| Test | PC Windows 11 de développement | PC 2 |
|---|---|---|
| QEMU extrait sans installation, clé ordinaire FAT32 16 Go | Bureau atteint | Non testé |
| WHPX | Initialisation et bureau validés | Non testé |
| TCG | Live utilisé, lenteur importante; jeu non mesuré | Non testé |
| Disque segmenté, écriture au-delà de 4 Gio | Écriture/relecture dédiée réussie | Non testé |
| Linux installé | Bureau utilisateur atteint via Jouer.cmd | Non testé |
| Steam et dépendances i386 | Installation terminée, Remote Play utilisé | Non testé |
| Remote Play | Très fluide selon utilisateur; résolution, FPS et réseau non consignés | Non testé |
| LAN puis autre réseau Internet | Scénarios distincts non documentés | Non testé |
| Firefox | Version 156.0.1 + HTTPS validés en live; système final non vérifié | Non testé |
| Souris absolue | Bureau normal, caméra trop rapide en jeu | Non testé |
| Souris relative | QMP absolute=false confirmé; jeu à retester | Non testé |
| Audio, clavier, manette | Pas de validation séparée consignée; manette non implémentée | Non testé |
| Arrêt propre/redémarrage/persistance complète | À confirmer; blocage du restart installateur observé | Non testé |
| Démarrage chronométré | Bureau live WHPX capturé à 110 s, pas une mesure exacte | Non testé |

Sur chacun des deux PC : noter CPU/RAM/Windows/support/profil/réseau; chronométrer lancement jusqu'au bureau puis Steam prêt. Tester WHPX et TCG sans cacher une lenteur rédhibitoire. Streamer le même jeu dix minutes à 720p/60 et relever statistiques (débit, perte, latence, décodage) et ressenti. Vérifier séparément son, clavier, caméra et manette si prise en charge. Refaire depuis un autre réseau Internet; 1080p/60 seulement si satisfaisant. Éteindre, éjecter, rebrancher, vérifier persistance. Un test prévu n'est pas un test réussi.
