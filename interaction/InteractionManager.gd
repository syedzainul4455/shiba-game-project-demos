extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var label: Label = $Label

const base_text = "[E] to interact"

var active_areas: Array = []
var can_interact: bool = true


func register_area(area: InteractionArea) -> void:
    active_areas.push_back(area)
    
func unregister_area(area: InteractionArea) -> void:
    var index = active_areas.find(area)
    if index != -1:
        active_areas.remove_at(index)


func _process(delta: float) -> void:
    if active_areas.size() > 0 and can_interact:
        # sort by nearest area
        active_areas.sort_custom(_sort_by_distance_to_player)

        var target_area: InteractionArea = active_areas[0]
        if target_area == null or not is_instance_valid(target_area):
            label.hide()
            return

        # show label text
        label.text = base_text + " " + target_area.action_name

        # Position label above the NPC, centered
        var label_width: float = max(label.size.x, label.get_minimum_size().x)
        var offset_y: float = -390.0
        var offset_x: float = -240
        label.global_position = target_area.global_position + Vector2(offset_x, offset_y)

        label.show()
    else:
        label.hide()


func _sort_by_distance_to_player(area1, area2) -> bool:
    var d1 = player.global_position.distance_to(area1.global_position)
    var d2 = player.global_position.distance_to(area2.global_position)
    return d1 < d2


func _input(event) -> void:
    if event.is_action_pressed("interact") and can_interact:
        if active_areas.size() > 0:
            can_interact = false
            label.hide()

            await active_areas[0].interact.call()

            can_interact = true
