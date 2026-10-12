# Performance du Remote Play dans la VM

La VM n'a pas de GPU : le rendu est **logiciel (llvmpipe)** et surtout le **décodage H.264** du flux Remote Play se fait **au CPU**. C'est le vrai goulot d'étranglement. Des avertissements « thread starvation » dans la console Steam indiquent un manque de temps CPU.

## Réglages appliqués / recommandés

### 1. Plus de vCPU (config)
`config/settings.json` : `"cpus": 8` (était 4). Le décodage logiciel et llvmpipe sont multi-threadés et profitent des cœurs. Testé sur un hôte 16 cœurs / 24 threads (i7-13700F). Prend effet au **prochain lancement** (`Jouer.cmd` / `Jouer-Jeu.cmd`), pas à chaud.

Ne pas augmenter `memoryMiB` au-delà de 4096 si l'hôte a peu de RAM libre : le swap côté Windows ralentirait tout. **Fermer les applications Windows avant de jouer** est souvent le gain le plus simple.

### 2. Optimisations dans le guest — `linux/optimize-gaming.sh`
À lancer une fois dans la session Xfce de la VM :
```bash
bash optimize-gaming.sh
```
- désactive le **compositing xfwm4** (libère du CPU, réduit le tearing/latence) ;
- désactive la **veille/extinction de l'écran** pendant le jeu ;
- rend ces réglages **permanents** via une entrée d'autostart.

Équivalent à chaud (sans le script), dans un terminal de la VM :
```bash
xfconf-query -c xfwm4 -p /general/use_compositing -s false; xset s off; xset -dpms
```

### 3. Réglages Steam Remote Play
Point de départ : **720p, 60 i/s, H.264, 10 Mbit/s**, avec statistiques détaillées (options avancées). Monter en 1080p seulement si le décodage CPU suit (surveiller les stats : décodage, images sautées). Une résolution plus basse = moins de charge de décodage.

### 4. Côté Windows hôte
- Fermer les applications gourmandes (RAM/CPU) avant une session.
- Si la caméra semble trop rapide : désactiver « Améliorer la précision du pointeur » (Panneau de configuration → Souris → Options du pointeur).
