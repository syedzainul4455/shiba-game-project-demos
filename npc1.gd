extends CharacterBody2D

@onready var speech_sound: AudioStreamPlayer = $AudioStreamPlayer

@export var dialog_lines: Array[String] = [
    "Hello there!",
    "It’s a beautiful day, isn’t it?",
    "Come back anytime if you want to chat."
]

var player_in_range: bool = false

func _process(delta: float) -> void:
    if player_in_range and Input.is_action_just_pressed("interact"):
        print("NPC: interact pressed")
        DialogManager.start_dialog(global_position, dialog_lines, speech_sound.stream)


func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("player"):
        player_in_range = true

func _on_area_exited(area: Area2D) -> void:
    if area.is_in_group("player"):
        player_in_range = false
