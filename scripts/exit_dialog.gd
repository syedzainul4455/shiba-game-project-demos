# exit_dialog.gd
extends ConfirmationDialog

func _ready():
    resizable = false
    get_ok_button().text = "Yes"
    get_cancel_button().text = "No"
    
    # Load and apply the theme
    var theme = load("res://dialog_theme.tres")
    if theme:
        self.theme = theme
        
        # Wait for the dialog to be fully initialized
        await get_tree().process_frame
        
        # Apply theme to specific ConfirmationDialog elements
        apply_theme_to_confirmation_dialog(theme)
        
        print("Theme applied successfully!")
    else:
        print("Failed to load theme! Check if path is correct: res://dialog_theme.tres")

    # Connect signals
    get_ok_button().pressed.connect(_on_confirm_quit)
    get_cancel_button().pressed.connect(_on_cancel)

# Apply theme specifically to ConfirmationDialog structure
func apply_theme_to_confirmation_dialog(theme_resource: Theme):
    # Apply to the main dialog
    self.theme = theme_resource
    
    # Apply to the content area
    if has_node("VBoxContainer"):
        get_node("VBoxContainer").theme = theme_resource
    
    # Apply to the label (message text)
    if has_node("VBoxContainer/Label"):
        get_node("VBoxContainer/Label").theme = theme_resource
        # Center the text
        get_node("VBoxContainer/Label").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        get_node("VBoxContainer/Label").vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Apply to buttons
    get_ok_button().theme = theme_resource
    get_cancel_button().theme = theme_resource
    
    # Apply to the panel background
    if has_node("Panel"):
        get_node("Panel").theme = theme_resource

func _on_confirm_quit():
    get_tree().quit()

func _on_cancel():
    hide()
