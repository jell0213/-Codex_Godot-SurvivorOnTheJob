class_name CharacterVisual2D
extends Node2D
## Presentation contract. A future Spine adapter extends this class and forwards
## these calls to its runtime. Gameplay never depends on a skeleton or animation.

func configure(_is_player: bool) -> void:
	pass

func set_motion(_motion: StringName) -> void:
	pass

func set_facing(_direction: Vector2) -> void:
	pass

func play_attack() -> void:
	pass

func set_playback_paused(_paused: bool) -> void:
	pass
