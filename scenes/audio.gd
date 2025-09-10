extends Control

@onready var menu_box: VBoxContainer = $Center/Frame/AudioVBox/VBoxContainer
@onready var sfx_move: AudioStreamPlayer = $Hover
@onready var sfx_press: AudioStreamPlayer = $Click

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

    # Focus first button
    $Center/Frame/AudioVBox/VBoxContainer.grab_focus()

    # Loop through all children of the VBoxContainer
    for b in menu_box.get_children():
        if b is Button:
            b.focus_entered.connect(_on_any_button_selected)
            b.mouse_entered.connect(_on_any_button_selected)
            b.pressed.connect(_on_any_button_pressed)

func _process(delta: float) -> void:
    pass

# Play sound when button selected
func _on_any_button_selected() -> void:
    sfx_move.stop()
    sfx_move.play()

# Play sound when button pressed
func _on_any_button_pressed() -> void:
    sfx_press.stop()
    sfx_press.play()

# Back button → Main Menu (smooth transition)


func _on_back_button_pressed() -> void:
        get_tree().change_scene_to_file("res://UI/options/OptionsMenu.tscn")
        

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):  # Esc by default
        _on_back_button_pressed()
