extends Control

var buttons : Array[Button] = []
var current_index := 0

func _ready():
    # Collect all buttons in the container
    for child in get_children():
        if child is Button:
            buttons.append(child)

    # Set initial focus
    if buttons.size() > 0:
        buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_down"):
        current_index = (current_index + 1) % buttons.size()
        buttons[current_index].grab_focus()

    elif event.is_action_pressed("ui_up"):
        current_index = (current_index - 1 + buttons.size()) % buttons.size()
        buttons[current_index].grab_focus()

    elif event.is_action_pressed("ui_accept"):
        # Simulate pressing the focused button
        buttons[current_index].emit_signal("pressed")
