extends Node2D  

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite = $Sprite2D
@onready var speech_sound = preload("res://audio/speech.wav")

var original_facing_right: bool = true
var is_turned_towards_player: bool = false
var original_position: Vector2
var bobbing_tween: Tween

const lines: Array[String] = [
    "Greetings, brave traveler!",
    "You've entered the **Shibonokoki Realm**...",    
    "A mystical land guarded by Shiba spirits!",
    "Press [F] to Exit the Dialog**...",
    "Roam with **[Arrow Keys]**.",
    "Leap chasms with **[Space]** or **[Up Arrow]**.",
    "Press [Space Two times] to Double Jump",
    "Speak with **[E]** to interact!",
    "Advance this tale with **[E]** again.",
    "Retreat with **[Q]**, **[Esc]**, or **[Backspace]**...",
    "Back to the Main Menu awaits!",
    "Shadows stir—will you rise?"
]

func _ready() -> void:
    if interaction_area:
        interaction_area.interact = Callable(self, "_on_interact")
    original_facing_right = not sprite.flip_h
    original_position = global_position
    DialogManager.dialog_finished.connect(_on_dialog_finished)

func is_player_behind_npc(player: Node2D) -> bool:
    var npc_facing_right = original_facing_right
    var player_to_npc = player.global_position - global_position
    if npc_facing_right and player_to_npc.x > 0:
        return true
    elif not npc_facing_right and player_to_npc.x < 0:
        return true
    return false

func turn_towards_player(player: Node2D) -> void:
    var player_to_npc = player.global_position - global_position
    var should_face_right = player_to_npc.x < 0
    var tween = create_tween()
    tween.tween_property(sprite, "rotation_degrees", -5.0, 0.1)
    tween.tween_property(sprite, "rotation_degrees", 0.0, 0.1)
    sprite.flip_h = not should_face_right
    is_turned_towards_player = true

func return_to_original_direction() -> void:
    sprite.flip_h = not original_facing_right
    is_turned_towards_player = false

func start_bobbing_animation() -> void:
    if bobbing_tween:
        bobbing_tween.kill()
    bobbing_tween = create_tween()
    bobbing_tween.set_loops()
    bobbing_tween.tween_property(self, "position:y", original_position.y - 3.0, 0.5)
    bobbing_tween.tween_property(self, "position:y", original_position.y + 3.0, 0.5)

func stop_bobbing_animation() -> void:
    if bobbing_tween:
        bobbing_tween.kill()
        bobbing_tween = null
    position.y = original_position.y

func return_to_original_position_and_tilt() -> void:
    position = original_position
    var tween = create_tween()
    tween.tween_property(sprite, "rotation_degrees", 5.0, 0.1)
    tween.tween_property(sprite, "rotation_degrees", 0.0, 0.1)

func _on_interact():
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("freeze_for_npc_dialog_start"):
        player.freeze_for_npc_dialog_start(self)
    if player:
        turn_towards_player(player)
    start_bobbing_animation()
    DialogManager.start_dialog(global_position + Vector2(0, -120), lines, speech_sound)

func _on_dialog_finished() -> void:
    stop_bobbing_animation()
    return_to_original_direction()
    return_to_original_position_and_tilt()
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("freeze_for_npc_dialog_end"):
        player.freeze_for_npc_dialog_end()

func _unhandled_input(event: InputEvent) -> void:
    pass
