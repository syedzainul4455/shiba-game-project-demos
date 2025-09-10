extends Control

@onready var audio_button = $Center/Frame/VBoxContainer/Audio_Button
@onready var video_button = $Center/Frame/VBoxContainer/Video_Button
@onready var controller_button = $Center/Frame/VBoxContainer/Controller_button
@onready var keyboard_button = $Center/Frame/VBoxContainer/Keyboard_Button
@onready var back_button = $Center/Frame/VBoxContainer/Back_button
@onready var click_sound = $Click
@onready var hover_sound = $Hover

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    # Connect button signals
    audio_button.pressed.connect(_on_audio_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

    # Hover/press sounds for all buttons
    for button in $Center/Frame/VBoxContainer.get_children():
        if button is Button:
            button.mouse_entered.connect(_on_any_button_selected)
            button.focus_entered.connect(_on_any_button_selected)
            button.pressed.connect(_on_any_button_pressed)

# -------------------------
# SOUND HANDLERS
# -------------------------
func _on_any_button_selected() -> void:
    hover_sound.play()

func _on_any_button_pressed() -> void:
    click_sound.play()

# -------------------------
# MENU ACTIONS
# -------------------------
func _on_audio_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/audio.tscn")

func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# -------------------------
# ESCAPE KEY HANDLING
# -------------------------
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _on_back_button_pressed()
