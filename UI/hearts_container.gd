extends HBoxContainer

@onready var HeartGuiClass = preload("res://UI/heart_gui.tscn")

# Store references to the heart nodes
var hearts: Array = []

# Returns array of heart nodes
func get_hearts() -> Array:
    return hearts

func _ready() -> void:
    # nothing yet — UI is built from setMaxHearts()
    pass

# Create all hearts when game starts
func setMaxHearts(max: int) -> void:
    # Clear any old hearts
    for h in hearts:
        h.queue_free()
    hearts.clear()

    # Add new hearts
    for i in range(max):
        var heart = HeartGuiClass.instantiate()
        add_child(heart)
        hearts.append(heart)

# Update hearts when health changes
func updateHearts(currentHealth: int) -> void:
    for i in range(hearts.size()):
        if i < currentHealth:
            hearts[i].updateHearts(true)   # full heart
        else:
            hearts[i].updateHearts(false)  # empty heart
