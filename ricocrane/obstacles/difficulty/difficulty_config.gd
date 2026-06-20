class_name DifficultyConfig
extends Resource

# --- TUNING ---
@export var obstacle_start_distance: float = 800.0
@export var skull_gap_min_by_distance: Curve
@export var skull_gap_max_by_distance: Curve
@export var obstacle_density_by_distance: Curve
@export var speed_friction_by_distance: Curve
