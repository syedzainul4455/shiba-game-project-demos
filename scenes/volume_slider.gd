extends HSlider

@export var bus_name: String
var bus_index: int

func _ready() -> void:
    bus_index = AudioServer.get_bus_index(bus_name)

    if bus_index == -1:
        push_error("Bus not found: %s" % bus_name)
        return

    # Set initial slider value from bus
    value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))

    # Connect slider signal
    value_changed.connect(_on_value_changed)


func _on_value_changed(value: float) -> void:
    var safe: float = max(value, 0.001) # explicitly typed
    AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe))
