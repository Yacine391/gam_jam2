# CLAUDE.md — RICOCRÂNE

> Fichier de contexte permanent. Toute session Claude Code lit ce fichier et
> doit s'y conformer. En cas de doute sur le design, **ce fichier fait foi**.

## 1. Le projet
RICOCRÂNE est un jeu d'arcade 2D créé pour un hackathon week-end (équipe :
Yacine, Dariya, Kays + un architecte IA dans une autre session).

- **Thème imposé : la mer.**
- **Règle imposée : aucun humain visible**, sauf **un seul homme chauve qui doit
  rester caché**.

Pitch : un **crabe** pilote un jetski et **rebondit de crâne de chauve en crâne
de chauve** pour garder sa vitesse — un jeu de momentum/skill. Vus de loin, les
crânes ressemblent à des rochers ; de près c'est un chauve qui grimace (= le gag,
et le respect de la règle « humain caché »). Le pilote étant un crabe, **aucun
humain n'est visible**.

**Objectif de design n°1 : que ce soit ADDICTIF** — boucle courte, « encore une
partie », chasse au score.

## 2. Le pilier de fun (à ne JAMAIS perdre de vue)
Ce n'est **PAS** un runner passif. **La vitesse vient des rebonds.** Le joueur
doit viser en permanence le prochain crâne pour ne pas ralentir et couler. C'est
ce qui transforme « runner basique » en « jeu de skill ». Chaque feature doit
servir cette boucle.

## 3. Mécanique cœur (la spec)
- Side-scroller 2D, caméra qui suit le joueur horizontalement.
- Le joueur avance vers la droite à `current_speed`.
- `current_speed` **décroît en continu** (friction). Sous `min_speed` → game over.
- Gravité : le jetski tombe vers la ligne d'eau et y rebondit mollement.
- Des **crânes** flottent à hauteurs/espacements variés et **bobent** (sin = houle).
- Input (Espace / clic / tap) = **plonger** (force vers le bas).
- Atterrir sur le **dessus** d'un crâne = **rebond + boost de `current_speed`**.
- **Timing parfait** : plus l'atterrissage est proche du sommet du crâne → plus
  gros boost (+ feedback visuel et sonore).
- **Combo** : chaque rebond consécutif **sans toucher l'eau** ↑ le multiplicateur.
  Toucher l'eau = reset du combo.
- `score = distance_parcourue * combo_multiplier`.
- **Game over** si `current_speed < min_speed` OU si le joueur sort de l'écran à
  gauche (mur de vague qui scrolle vers la droite). **Restart instantané** (R / clic).
- Génération **procédurale infinie** des crânes devant, suppression derrière.

Plus tard (PAS en greybox) : obstacles (mines, bouées, tourbillons, jetskis
fantômes — jamais d'humain), **boss MEGA CRÂNE** périodique = rampe géante, boost
actif, leaderboard local, skins.

## 4. Stack & contraintes techniques
- **Godot 4.7**, **GDScript** — **PAS** de C#/.NET.
- 2D uniquement.
- Cible : **export Web HTML5** (renderer *Compatibility*) → jouable navigateur sur
  **itch.io**. Éviter tout ce qui casse en web (threads exotiques, fonctions non
  supportées par le renderer Compatibility).
- 60 FPS, tous les mouvements **frame-rate independent** (utiliser `delta`).

## 5. Architecture / fichiers
Scènes (PascalCase) + scripts (snake_case) :
- `Main.tscn` / `main.gd` — point d'entrée : start, game over, restart.
- `Player.tscn` / `player.gd` — jetski : mouvement, gravité, plongée, détection de
  rebond, gestion de `current_speed`.
- `Skull.tscn` / `skull.gd` — crâne : bob (houle), zone de rebond (Area2D), calcul
  du timing parfait.
- `spawner.gd` — génération procédurale / suppression des crânes.
- `hud.gd` — affichage score, vitesse, combo.
- `game_state.gd` — **autoload/singleton** : score, combo, état de partie, signaux
  globaux.

## 6. Conventions de code
- GDScript **typé statiquement** partout
  (`var speed: float = 0.0`, `func _on_bounce(skull: Skull) -> void:`).
- `snake_case` pour variables/fonctions ; `PascalCase` pour classes (`class_name`)
  et noms de nœuds.
- **TOUTES** les constantes de gameplay en `@export` (friction, bounce_boost,
  gravity, dive_force, min_speed, perfect_window, skull_spacing, etc.).
  **Aucun nombre magique** en dur dans la logique.
- Communication par **signaux** (ex. `signal bounced(is_perfect)`), pas de
  couplage en dur entre nœuds.
- Fonctions courtes, une responsabilité chacune. Pas de god-script.
- Marquer les blocs réglables : `# --- TUNING ---`.

## 7. Assets
- Tous les visuels = **sprites 2D** générés via Higgsfield (fournis par
  l'architecte), sur **fond vert uni** à chroma-key.
- **Greybox d'abord** : tout en primitives (rectangles/cercles colorés), **AUCUN
  art** tant que la boucle n'est pas fun. Les sprites arrivent en Phase 2.
- Style cible : cartoon, contours épais, palette néon vaporwave (magenta / teal /
  orange).

## 8. Règles du jam (à NE JAMAIS violer)
- Aucun personnage humain visible. Seul humain = le chauve, « caché » (lit comme un
  rocher de loin). Le pilote est un **crabe**.
- Le rendu final doit être **jouable sur itch.io** (export web HTML5).

## 9. Phase actuelle
**Phase 1 — Greybox.** Objectif unique : rendre la boucle momentum + rebond +
combo **FUN** avec des primitives. Pas d'art, pas d'audio, pas de menu sophistiqué.
Juste : ça démarre sur une partie jouable, on rebondit, on chase le combo, on
meurt, on recommence instantanément — et on a envie de recommencer.

## 10. Règles pour toi, Claude Code
- Reste dans le scope de la **phase actuelle**. Pas de scope creep.
- Priorité absolue : **la boucle doit être fun, et tout doit être tunable** via
  `@export`.
- Code propre, modulaire, typé.
- Quand tu finis une étape : dis clairement **quelle scène lancer** et **quels
  `@export` ajuster** pour régler le feel.
- Yacine relaie les décisions de l'architecte (autre session). En cas de doute,
  suis ce fichier.
