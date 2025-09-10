extends Camera2D

# Exported values to set the camera boundaries
@export var cam_limit_left: int = 500
@export var cam_limit_right: int = 2000
@export var cam_limit_top: int = 300
@export var cam_limit_bottom: int = 330

func _ready() -> void:
    # Make this camera the active one
    make_current()

    # Enable smoothing (Camera2D has built-in properties in Godot 4)
    position_smoothing_enabled = true
    position_smoothing_speed = 5.0  # Adjust as needed

    # Apply camera limits
    limit_left = cam_limit_left
    limit_right = cam_limit_right
    limit_top = cam_limit_top
    limit_bottom = cam_limit_bottom
