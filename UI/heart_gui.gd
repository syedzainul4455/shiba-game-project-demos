extends Panel

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    # Make sure it starts as full
    updateHearts(true)

# Toggle full/empty heart
func updateHearts(full: bool) -> void:
    if full:
        sprite.frame = 0   # full heart frame
    else:
        sprite.frame = 3   # empty heart frame
    sprite.visible = true
