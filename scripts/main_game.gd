extends Node2D

@onready var hearts_container = $UI/heartsContainer
@onready var player = $Player


func _ready() -> void:
    if hearts_container:
        hearts_container.visible = true
        print("✅ heartsContainer is visible")
    else:
        print("❌ heartsContainer not found")

    if player and hearts_container:
        # Set up hearts UI to match player max health
        hearts_container.setMaxHearts(player.maxHealth)
        hearts_container.updateHearts(player.currentHealth)
        player.healthChanged.connect(_on_player_health_changed)

func _on_player_health_changed(currentHealth: int) -> void:
    if hearts_container:
        hearts_container.updateHearts(currentHealth)
