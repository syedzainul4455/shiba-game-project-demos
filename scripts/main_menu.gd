extends Control

@onready var menu_box: VBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer
@onready var sfx_move: AudioStreamPlayer = $Hover
@onready var sfx_press: AudioStreamPlayer = $Click
@onready var exit_dialog: ConfirmationDialog = $ExitDialog
@onready var custom_cursor: TextureRect = $CursorLayer/CustomCursor
@onready var cursor_layer: CanvasLayer = $CursorLayer
@onready var fade_rect: ColorRect = $Dim

var current_index: int = 0

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    # Prepare OS-level custom cursor image once (applied when dialog is open)
    _prepare_os_cursor()

    # Fade-in at start if Dim starts opaque
    if fade_rect:
        if fade_rect.modulate.a > 0.0:
            var t_in: Tween = create_tween()
            t_in.tween_property(fade_rect, "modulate:a", 0.0, 0.25)
        else:
            fade_rect.modulate.a = 0.0

    # Focus first button
    var first_btn: Button = menu_box.get_node("Start_Button") as Button
    if first_btn:
        current_index = 0
        first_btn.grab_focus()

    # Connect all buttons
    for b in menu_box.get_children():
        if b is Button:
            b.focus_entered.connect(_on_any_button_selected)
            b.mouse_entered.connect(_on_any_button_selected)
            b.pressed.connect(func(): _on_any_button_pressed(b))

    # Exit dialog setup
    if exit_dialog:
        exit_dialog.hide()
        exit_dialog.get_ok_button().text = "Yes"
        exit_dialog.get_cancel_button().text = "No"
        exit_dialog.confirmed.connect(func(): get_tree().quit())

    # Initialize cursor
    if custom_cursor:
        custom_cursor.visible = true
        custom_cursor.position = get_global_mouse_position()
    if cursor_layer:
        cursor_layer.layer = 200

func _process(delta: float) -> void:
    if custom_cursor:
        custom_cursor.position = get_global_mouse_position()

# --------------------------
# Input Handling
# --------------------------
func _unhandled_input(event: InputEvent) -> void:
    # Exit dialog handling first
    if exit_dialog and exit_dialog.visible:
        if event.is_action_pressed("ui_accept"):
            sfx_press.play()
            exit_dialog.emit_signal("confirmed") # triggers quit
            exit_dialog.hide()
            # Restore in-game cursor after dialog closes
            _hide_os_cursor_and_show_custom()
        elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
            sfx_press.play()
            exit_dialog.hide()
            # Restore in-game cursor after dialog closes
            _hide_os_cursor_and_show_custom()
        return

    # Quit actions (Esc / Backspace / Q mapped to ui_cancel)
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
        sfx_press.play()
        if exit_dialog and not exit_dialog.visible:
            exit_dialog.popup_centered()
            var ok_btn: Button = exit_dialog.get_ok_button()
            if ok_btn:
                ok_btn.call_deferred("grab_focus")
            # Show scaled OS cursor above dialog and hide in-game cursor sprite
            _show_os_cursor_and_hide_custom()
        return

    # W / S navigation
    if event.is_action_pressed("ui_up_custom"):
        _move_focus(-1)
    elif event.is_action_pressed("ui_down_custom"):
        _move_focus(1)

    # Toggle fullscreen
    if event.is_action_pressed("toggle_fullscreen"):
        _toggle_fullscreen()

# --------------------------
# Fullscreen Toggle
# --------------------------
func _toggle_fullscreen() -> void:
    var current_mode: int = DisplayServer.window_get_mode()
    if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# --------------------------
# Menu Button Logic
# --------------------------
func _move_focus(dir: int) -> void:
    var buttons: Array[Button] = []
    for b in menu_box.get_children():
        if b is Button:
            buttons.append(b)

    if buttons.is_empty():
        return

    current_index = (current_index + dir) % buttons.size()
    if current_index < 0:
        current_index = buttons.size() - 1

    buttons[current_index].grab_focus()
    sfx_move.play()

func _on_any_button_selected() -> void:
    sfx_move.stop()
    sfx_move.play()

func _on_any_button_pressed(btn: Button) -> void:
    sfx_press.stop()
    sfx_press.play()
    await _press_bounce(btn)

    match btn.name:
        "Start_Button":
            await _fade_to_black()
            get_tree().change_scene_to_file("res://scenes/main_game.tscn")

        "Option_Button":
            await _fade_to_black()
            get_tree().change_scene_to_file("res://UI/options/OptionsMenu.tscn")

        "Achievement_button":
            pass # Not yet implemented

        "Exit_button":
            if exit_dialog:
                exit_dialog.popup_centered()
                var ok_btn2: Button = exit_dialog.get_ok_button()
                if ok_btn2:
                    ok_btn2.call_deferred("grab_focus")
                # Show scaled OS cursor above dialog and hide in-game cursor sprite
                _show_os_cursor_and_hide_custom()

# --------------------------
# Cursor helpers
# --------------------------
func _prepare_os_cursor() -> void:
    # Prefer the same texture used by the in-game cursor for a perfect match
    if custom_cursor and custom_cursor.texture is Texture2D:
        var t: Texture2D = custom_cursor.texture as Texture2D
        _cursor_base_image = t.get_image()
        if _cursor_base_image:
            var base_w: int = t.get_width()
            var base_h: int = t.get_height()
            var sx: float = max(custom_cursor.scale.x, 0.1)
            var sy: float = max(custom_cursor.scale.y, 0.1)
            _cursor_target_w = int(round(base_w * sx))
            _cursor_target_h = int(round(base_h * sy))
            return

    # Fallback to loading the asset directly
    var tex: Resource = load("res://scripts/cursor_click_resized.png")
    if tex is Texture2D:
        _cursor_base_image = (tex as Texture2D).get_image()
        if _cursor_base_image:
            _cursor_target_w = _cursor_base_image.get_width()
            _cursor_target_h = _cursor_base_image.get_height()

var _cursor_base_image: Image
var _cursor_target_w: int = 0
var _cursor_target_h: int = 0

func _show_os_cursor_and_hide_custom() -> void:
    # Use a fixed pixel size matching the in-game cursor at startup
    if _cursor_base_image:
        var w: int = max(_cursor_target_w, 1)
        var h: int = max(_cursor_target_h, 1)
        var img: Image = _cursor_base_image.duplicate()
        if img.get_width() != w or img.get_height() != h:
            img.resize(w, h, Image.INTERPOLATE_LANCZOS)
        var tex: ImageTexture = ImageTexture.create_from_image(img)
        Input.set_custom_mouse_cursor(tex)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    if custom_cursor:
        custom_cursor.visible = false

func _hide_os_cursor_and_show_custom() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if custom_cursor:
        custom_cursor.visible = true

# --------------------------
# Visual Effects
# --------------------------
func _press_bounce(node: CanvasItem) -> void:
    node.pivot_offset = node.size / 2
    var t: Tween = create_tween().set_parallel(false)
    t.tween_property(node, "scale", Vector2(0.92, 0.92), 0.08)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.14)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    await t.finished

func _fade_to_black() -> void:
    if not fade_rect:
        return
    var t := create_tween()
    t.tween_property(fade_rect, "modulate:a", 1.0, 0.25)
    await t.finished
