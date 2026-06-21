# Audio — note pour Yacine

## Pour activer l'AudioManager

Dans `project.godot`, ajouter en autoload (section [autoload]) :
```
AudioManager="*res://audio/AudioManager.tscn"
```

## Sons générés automatiquement (generate_sfx.py)

Les fichiers .wav sont déjà dans audio/sfx/ et audio/music/ — générés par script Python.
Pour les remplacer par de vrais sons plus tard : même noms, même dossiers.

| Fichier | Description |
|---|---|
| `sfx/bonk.wav` | Rebond crâne normal |
| `sfx/perfect.wav` | Rebond parfait |
| `sfx/splash.wav` | Toucher l'eau (combo perdu) |
| `sfx/combo_up.wav` | Combo qui monte |
| `sfx/combo_lost.wav` | Combo perdu |
| `sfx/game_over.wav` | Game over |
| `music/theme.wav` | Musique en boucle |

## Une fois les fichiers placés

Dans Godot, ouvrir `audio/AudioManager.tscn` et assigner chaque fichier
au bon AudioStreamPlayer dans l'Inspecteur (drag & drop depuis le FileSystem).
