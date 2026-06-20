# Intégration des obstacles — note pour Yacine

## Interface commune à tous les obstacles

Chaque obstacle expose :
- `signal hit` — émis quand le joueur entre en contact
- `func check_hit(player_pos: Vector2, player_half_w: float, player_half_h: float) -> bool`
- Tous les paramètres de tuning en `@export`

## Comment les instancier (même pattern que les crânes)

```gdscript
var obs: Mine = mine_scene.instantiate() as Mine
obs.position = Vector2(spawn_x, spawn_y)
obs.hit.connect(_on_obstacle_hit)
skull_container.add_child(obs)
```

## Détection de collision (dans main.gd)

Même pattern que `_check_skull_bounces()` — appelle `check_hit()` dans `_process` :

```gdscript
func _check_obstacle_hits() -> void:
    var pp: Vector2 = player.position
    var hw: float = player.player_width * 0.5
    var hh: float = player.player_height * 0.5
    for obs in obstacle_container.get_children():
        if obs.check_hit(pp, hw, hh):
            obs.hit.emit()
            GameState.trigger_game_over()
            return
```

## Réactions suggérées par obstacle

| Obstacle | Réaction recommandée |
|---|---|
| Mine | `GameState.trigger_game_over()` — mort instantanée |
| Buoy | `player.current_speed -= obs.speed_penalty` — ralentissement |
| Whirlpool | `player.current_speed -= pull * delta` chaque frame dans la zone |
| GhostJetski | `GameState.trigger_game_over()` — mort instantanée |

## DifficultyConfig

Resource à créer dans l'éditeur Godot (clic droit > New Resource > DifficultyConfig).
Brancher sur le Spawner via `@export var difficulty: DifficultyConfig`.
Lire `difficulty.obstacle_start_distance` pour savoir quand faire apparaître les obstacles.
Lire `difficulty.obstacle_density_by_distance.sample(distance / max_distance)` pour la densité.
