extends TextureButton

@export var bus_name: String = "Master"        # "Master", "Music", or "SFX"
@export var linked_slider_path: NodePath       # Drag the HSlider node here
@export var lock_slider_when_muted := true

var linked_slider: HSlider
var _last_value := 0.8
const EPS := 0.001

func _ready() -> void:
    toggle_mode = true
    linked_slider = get_node_or_null(linked_slider_path) as HSlider

    if linked_slider:
        linked_slider.value_changed.connect(_on_slider_changed)

    toggled.connect(_on_toggled)
    _sync_from_bus()

# Sync state from AudioServer at startup
func _sync_from_bus() -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx == -1: return

    var is_muted := AudioServer.is_bus_mute(idx)
    var linear := db_to_linear(AudioServer.get_bus_volume_db(idx))

    button_pressed = is_muted
    if not is_muted:
        _last_value = max(linear, EPS)

    if linked_slider:
        linked_slider.editable = not is_muted if lock_slider_when_muted else true
        linked_slider.value = 0.0 if is_muted else linear

# Called when mute button pressed/unpressed
func _on_toggled(pressed: bool) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx == -1: return

    AudioServer.set_bus_mute(idx, pressed)

    if linked_slider:
        if pressed:
            # Save and lock slider
            _last_value = max(linked_slider.value, EPS)
            linked_slider.value = 0.0
            if lock_slider_when_muted:
                linked_slider.editable = false
        else:
            # Restore and unlock slider
            linked_slider.editable = true
            linked_slider.value = _last_value
            AudioServer.set_bus_volume_db(idx, linear_to_db(_last_value))

# Called when slider moved
func _on_slider_changed(v: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx == -1: return

    _last_value = max(v, EPS)

    # If user moves slider while muted → unmute automatically
    if AudioServer.is_bus_mute(idx) and v > EPS:
        button_pressed = false
        _on_toggled(false)

    if not AudioServer.is_bus_mute(idx):
        AudioServer.set_bus_volume_db(idx, linear_to_db(v))
