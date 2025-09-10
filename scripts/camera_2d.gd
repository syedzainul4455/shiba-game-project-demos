extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Only set the right limit as requested. All other settings remain unchanged.
    limit_right = 6500


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
