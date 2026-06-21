# Intégration Dariya → Yacine

## Ce que tu dois ajouter dans Main.tscn (3 nœuds, 3 lignes)

Ouvre Main.tscn dans l'éditeur Godot et ajoute ces 3 scènes instanciées
comme enfants de **Main** (node racine), dans cet ordre, après le HUD :

| Scène à instancier           | Nom du nœud      |
|------------------------------|------------------|
| `ui/TitleOverlay.tscn`       | `TitleOverlay`   |
| `ui/ComboDisplay.tscn`       | `ComboDisplay`   |
| `fx/JuiceManager.tscn`       | `JuiceManager`   |

### En texte brut à coller à la fin de Main.tscn

Si tu préfères éditer le fichier texte, ajoute ces lignes
**après** le dernier `[node ...]` existant et après avoir ajouté
les ext_resource correspondantes en haut du fichier.

**En haut du fichier, dans les ext_resource** :
```
[ext_resource type="PackedScene" uid="uid://dtitle00001" path="res://ui/TitleOverlay.tscn" id="10_title"]
[ext_resource type="PackedScene" uid="uid://dcombod0001" path="res://ui/ComboDisplay.tscn" id="11_combo"]
[ext_resource type="PackedScene" uid="uid://djuicem0001" path="res://fx/JuiceManager.tscn" id="12_juice"]
```

**À la fin du fichier** :
```
[node name="TitleOverlay" parent="." instance=ExtResource("10_title")]

[node name="ComboDisplay" parent="." instance=ExtResource("11_combo")]

[node name="JuiceManager" parent="." instance=ExtResource("12_juice")]
```

## Ce que ça fait
- **TitleOverlay** : écran "RICOCRÂNE" qui apparaît à chaque game over,
  affiche le score + meilleur score de la session, disparaît au restart.
- **ComboDisplay** : gros compteur combo ×N pulsé au centre d'écran,
  qui grandit et change de couleur (jaune → magenta) avec le combo.
- **JuiceManager** : screen shake (Perlin) au rebond, hit-stop court sur
  rebond parfait, particules d'éclaboussure au rebond, lignes de vitesse
  en CanvasLayer quand la vitesse est élevée.

## @export réglables (dans l'inspecteur)
### TitleOverlay
- `title_font_size` / `body_font_size` — taille des textes
- `fade_in_duration` — vitesse du fade-in

### ComboDisplay
- `base_font_size` / `max_font_size` — fourchette de taille
- `pulse_duration` — durée du pulse au rebond
- `fade_out_delay` — combien de temps le combo reste visible sans rebond

### JuiceManager
- `shake_on_bounce` / `shake_on_perfect` — intensité du shake (0–1)
- `shake_decay` — vitesse de décroissance du shake
- `max_shake_offset` — amplitude max en pixels
- `hitstop_duration` — durée du freeze parfait en secondes
- `splash_count` / `splash_color` — particules d'éclaboussure

### SpeedLinesDrawer (enfant de JuiceManager → SpeedLinesLayer)
- `speed_threshold` — à partir de quelle vitesse les lignes apparaissent
- `speed_max` — vitesse à laquelle les lignes sont à fond
- `line_count` / `line_color` / `line_width`
