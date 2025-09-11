extends Control

@onready var menu_box: VBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer
@onready var fade_rect: ColorRect = $Dim
@onready var exit_dialog: ConfirmationDialog = $ExitDialog
@onready var sfx_move: AudioStreamPlayer = $Hover
@onready var sfx_press: AudioStreamPlayer = $Click
@onready var custom_cursor: TextureRect = $CursorLayer/CustomCursor
@onready var cursor_layer: CanvasLayer = $CursorLayer

var current_index: int = 0

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT, true)
    size = get_viewport().get_visible_rect().size

    # Ensure clean entry
    get_tree().paused = false
    if fade_rect:
        fade_rect.modulate.a = 0.0

    # Custom cursor in menu only
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if custom_cursor:
        custom_cursor.visible = true
        custom_cursor.position = get_global_mouse_position()
    _elevate_cursor()

    # Focus first button
    var first_btn: Button = menu_box.get_node("Start_Button") as Button
    if first_btn:
        current_index = 0
        first_btn.grab_focus()

    # Connect all buttons under the menu box
    for b in menu_box.get_children():
        if b is Button:
            b.focus_entered.connect(_on_any_button_selected)
            b.mouse_entered.connect(_on_any_button_selected)
            b.pressed.connect(func(): _on_any_button_pressed(b))

    # Basic exit dialog wiring if present
    if exit_dialog:
        exit_dialog.hide()
        exit_dialog.get_ok_button().text = "Yes"
        exit_dialog.get_cancel_button().text = "No"
        exit_dialog.confirmed.connect(func(): get_tree().quit())

func _process(delta: float) -> void:
    if custom_cursor:
        custom_cursor.position = get_global_mouse_position()

# --------------------------
# Input Handling for Exit Dialog
# --------------------------
func _unhandled_input(event: InputEvent) -> void:
    if exit_dialog and exit_dialog.visible:
        if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
            if sfx_press:
                sfx_press.play()
            exit_dialog.emit_signal("confirmed")
            exit_dialog.hide()
            # Keep OS cursor hidden and custom cursor visible in menu
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            if custom_cursor:
                custom_cursor.visible = true
        return

    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
        if sfx_press:
            sfx_press.play()
        if exit_dialog and not exit_dialog.visible:
            exit_dialog.popup_centered()
            var ok_btn: Button = exit_dialog.get_ok_button()
            if ok_btn:
                ok_btn.call_deferred("grab_focus")
            # Ensure custom cursor is above the dialog and visible
            _elevate_cursor()
            Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            if custom_cursor:
                custom_cursor.visible = true
        return

func _on_any_button_pressed(btn: Button) -> void:
    if sfx_press:
        sfx_press.stop()
        sfx_press.play()
    await _fade_to_black()

    match btn.name:
        "Start_Button":
            if "start_loading" in LoadingScreen:
                LoadingScreen.start_loading("res://scenes/main_game.tscn")
            else:
                get_tree().change_scene_to_file("res://scenes/main_game.tscn")

        "Option_Button":
            get_tree().change_scene_to_file("res://UI/options/OptionsMenu.tscn")

        "Exit_button":
            if exit_dialog:
                exit_dialog.popup_centered()
                var ok_btn2: Button = exit_dialog.get_ok_button()
                if ok_btn2:
                    ok_btn2.call_deferred("grab_focus")
                _show_os_cursor_and_hide_custom()

func _on_any_button_selected() -> void:
    if sfx_move:
        sfx_move.stop()
        sfx_move.play()

func _fade_to_black() -> void:
    if not fade_rect:
        return
    var t := create_tween()
    t.tween_property(fade_rect, "modulate:a", 1.0, 0.25)
    await t.finished

# --------------------------
# Cursor helpers
# --------------------------
func _elevate_cursor() -> void:
    if cursor_layer:
        cursor_layer.layer = 10000
    if custom_cursor:
        custom_cursor.top_level = true
        custom_cursor.z_index = 10000

func _show_os_cursor_and_hide_custom() -> void:
    # No-op: we keep OS cursor hidden in menus per requirement
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if custom_cursor:
        custom_cursor.visible = true

func _hide_os_cursor_and_show_custom() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    if custom_cursor:
        custom_cursor.visible = true
