extends TextureRect

func _ready() -> void:
    # Ensure this Control draws independently of parent transforms
    set_as_top_level(true)
    # Force cursor to the highest possible drawing order
    var p := get_parent()
    while p and not (p is CanvasLayer):
        p = p.get_parent()
    if p and (p is CanvasLayer):
        (p as CanvasLayer).layer = 200   # ensure above dialogs
    z_index = 10000                # absurdly high, always on top
    z_as_relative = false           # not relative to siblings

    # Make sure it's mouse filter ignores input (doesn't block clicks)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Slightly enlarge the in-game cursor sprite
    scale = Vector2(1.25, 1.25)

func _process(delta: float) -> void:
    # Follow the mouse every frame
    position = get_viewport().get_mouse_position()
