# Rico Crane — Jet-ski Racing

Rico Crane est un jeu de course en jet-ski inspiré des jeux de karting. Le joueur choisit d’abord un animal ou un monstre, puis sélectionne un circuit avant d’affronter plusieurs bots.

## Objectif

Terminer les **3 tours** du circuit avant les autres concurrents.

Pendant la course, il faut éviter les bombes, récupérer les boîtes mystères et utiliser les objets obtenus pour ralentir ou éliminer les bots.

## Comment jouer

| Action | Touche |
|---|---|
| Avancer | `Z` |
| Tourner à gauche | `Q` |
| Reculer / freiner | `S` |
| Tourner à droite | `D` |
| Utiliser l’objet mystère | Clic gauche ou `Espace` |
| Recommencer la partie | `R` |

## Déroulement d’une partie

1. Choisir un animal ou un monstre.
2. Choisir un circuit.
3. Attendre le feu de départ :
   - rouge : personne ne bouge ;
   - orange : le joueur peut commencer à accélérer ;
   - vert : tous les concurrents démarrent.
4. Faire 3 tours et franchir la ligne d’arrivée avant les bots.

La mini-carte située en haut à gauche montre la position du joueur et celle des bots. Le compteur placé sous la mini-carte indique le nombre de tours effectués.

## Boîtes mystères

Les boîtes mystères sont placées sur le circuit. En passant dessus, une roulette sélectionne un objet aléatoire. L’objet obtenu apparaît dans l’interface et peut ensuite être utilisé avec le clic gauche ou la barre d’espace.

Objets disponibles :

- projectile pour attaquer un concurrent ;
- flaque qui ralentit les adversaires ;
- accélération temporaire ;
- poulet rare qui attaque le concurrent devant en le picorant ;
- Ilyas rare qui se place devant un concurrent et le propulse grâce à son crâne chauve.

Les bots peuvent eux aussi récupérer et utiliser des objets mystères.

## Bombes et élimination

Le joueur et les bots sont vulnérables aux bombes.

Chaque bombe touchée :

- ralentit le concurrent ;
- l’immobilise brièvement ;
- le fait repartir un peu plus loin en arrière sur le circuit.

Après **3 impacts**, le concurrent est éliminé et termine sur la plage. Les concurrents éliminés apparaissent à la fin du classement.

## Victoire et classement

La course se termine après le troisième tour du joueur ou lorsque les positions finales sont déterminées.

Le classement final est entièrement visuel :

- portraits des animaux et monstres ;
- médailles indiquant l’ordre d’arrivée ;
- couleurs des jet-skis ;
- croix rouge pour les concurrents éliminés.

## Lancer le projet dans Godot

1. Installer **Godot 4**.
2. Ouvrir Godot.
3. Cliquer sur **Importer**.
4. Sélectionner le fichier `project.godot`.
5. Ouvrir le projet puis cliquer sur le bouton **Run Project** ou appuyer sur `F6`/`F5` selon la scène lancée.

## Projet

Jeu réalisé sous Godot dans le cadre d’une game jam, avec une contrainte principale : limiter au maximum l’utilisation de texte dans l’interface et privilégier les éléments visuels.

## Marée mécanique

La marée fait partie du gameplay : elle reste basse, monte progressivement, reste haute, puis redescend. Quand elle est haute, le courant pousse tous les jet-skis latéralement et réduit leur vitesse maximale. Il faut contre-braquer avec **Q** et **D** pour rester sur le circuit. Le sens du courant change à chaque nouveau cycle. L'indicateur animé en haut de l'écran montre le niveau de la marée et la direction du courant, sans texte.
