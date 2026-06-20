class_name Obstacle
extends Node2D

signal hit

@export var lethal: bool = true
@export var speed_penalty: float = 0.0

func check_hit(_player_pos: Vector2, _player_half_w: float, _player_half_h: float) -> bool:
	return false
