extends Control

# -------------------------
# NODE REFS (match your tree)
# -------------------------
@onready var audio_button: Button      = $Center/Frame/VBoxContainer/Audio_Button
@onready var video_button: Button      = $Center/Frame/VBoxContainer/Video_Button
@onready var controller_button: Button = $Center/Frame/VBoxContainer/Controller_button
@onready var keyboard_button: Button   = $Center/Frame/VBoxContainer/Keyboard_Button
@onready var back_button: Button       = $Center/Frame/VBoxContainer/Back_button

@onready var hover_sound: AudioStreamPlayer = $Hover
@onready var click_sound: AudioStreamPlayer = $Click
@onready var fade_rect: ColorRect           = $Dim

# -------------------------
# TARGET SCENES
# -------------------------
const PATH_AUDIO       := "res://scenes/audio.tscn"
const PATH_VIDEO       := ""  # not wired yet
const PATH_CONTROLLER  := ""  # not wired yet
const PATH_KEYBOARD    := ""  # not wired yet
const PATH_MAIN_MENU   := "res://scenes/Main_Menu.tscn"  # <-- fixed path

# -------------------------
# LIFECYCLE
# -------------------------
func _ready() -> void:
    # Hide cursor (HTML5 safe)
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    # Fade in
    if fade_rect:
        if fade_rect.modulate.a > 0.0:
            var t_in := create_tween()
            t_in.tween_property(fade_rect, "modulate:a", 0.0, 0.25)
        else:
            fade_rect.modulate.a = 0.0

    # Focus first button
    if audio_button:
        audio_button.grab_focus()

    # Wire menu buttons
    _wire_button(audio_button,      PATH_AUDIO)
    _wire_button(video_button,      PATH_VIDEO)
    _wire_button(controller_button, PATH_CONTROLLER)
    _wire_button(keyboard_button,   PATH_KEYBOARD)

    # Back button explicitly goes back
    back_button.pressed.connect(_go_back)

    # Hover sound for ALL buttons
    for n in $Center/Frame/VBoxContainer.get_children():
        if n is Button:
            n.mouse_entered.connect(_on_hover_any)
            n.focus_entered.connect(_on_hover_any)

    # Make sure back button is keyboard focusable in HTML5
    back_button.focus_mode = Control.FOCUS_ALL


# -------------------------
# WIRING / COMMON HANDLERS
# -------------------------
func _wire_button(btn: Button, scene_path: String) -> void:
    if not btn:
        return
    btn.pressed.connect(func(): await _handle_button_press(btn, scene_path))

func _on_hover_any() -> void:
    if hover_sound:
        hover_sound.stop()
        hover_sound.play()

func _handle_button_press(btn: Button, scene_path: String) -> void:
    if click_sound:
        click_sound.stop()
        click_sound.play()

    await _press_bounce(btn)

    if scene_path == "":
        return

    await _fade_to_black()

    var error := get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_warning("Scene not found: %s" % scene_path)


# -------------------------
# BACK / ESC / Q / BACKSPACE
# -------------------------
func _go_back() -> void:
    await _handle_button_press(back_button, PATH_MAIN_MENU)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"): # ESC, Q, or Backspace
        _go_back()


# -------------------------
# TWEENS
# -------------------------
func _press_bounce(node: Control) -> void:
    node.pivot_offset = node.size / 2
    var t := create_tween()
    t.tween_property(node, "scale", Vector2(0.92, 0.92), 0.08)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(node, "scale", Vector2.ONE, 0.14)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    await t.finished

func _fade_to_black() -> void:
    if not fade_rect:
        return
    var t := create_tween()
    t.tween_property(fade_rect, "modulate:a", 1.0, 0.25)
    await t.finished
