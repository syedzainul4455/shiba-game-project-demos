extends Node2D

@onready var heartsContainer = $UI/heartsContainer
@onready var player = $player  # safer name to avoid cyclic reference

func _ready() -> void:
    # Setup hearts UI from player stats
    heartsContainer.setMaxHearts(player.maxHealth)
    heartsContainer.updateHearts(player.currentHealth)

    # Connect signal so UI updates automatically on health change
    player.healthChanged.connect(heartsContainer.updateHearts)

func _process(delta: float) -> void:
    pass
