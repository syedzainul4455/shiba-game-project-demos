extends TextureRect

@export var hotspot: Vector2 = Vector2(4, 4)    # click point inside your PNG
@export var target_size: int = 32               # desired cursor size in px (longest side)

func _ready() -> void:
    # Hide OS cursor so only your custom one is visible
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    # Make sure this cursor draws and updates regardless of pause/parents
    top_level = true
    z_index = 4096
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Scale the texture down to a normal cursor size
    _apply_target_size()

func _process(_delta: float) -> void:
    position = get_viewport().get_mouse_position() - hotspot

func _apply_target_size() -> void:
    if texture == null:
        return
    # TextureRect way to scale: set size and use STRETCH_SCALE
    stretch_mode = TextureRect.STRETCH_SCALE
    var tex_w = texture.get_width()
    var tex_h = texture.get_height()
    var longest = float(max(tex_w, tex_h))
    if longest <= 0.0:
        return
    var scale_factor = float(target_size) / longest
    size = Vector2(tex_w * scale_factor, tex_h * scale_factor)
