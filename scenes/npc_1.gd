extends Node2D  

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite = $Sprite2D
@onready var speech_sound = preload("res://audio/speech.wav")

# NPC turning behavior variables
var original_facing_right: bool = true  # Store original facing direction
var is_turned_towards_player: bool = false  # Track if currently turned towards player
var original_position: Vector2  # Store original position
var bobbing_tween: Tween  # Store the bobbing animation

const lines: Array[String] = [
    "Greetings, brave traveler!",
    "You've entered the **Shibonokoki Realm**...",
    "A mystical land guarded by Shiba spirits!",
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
    # Ensure that the interact callable is assigned correctly
    interaction_area.interact = Callable(self, "_on_interact")
    
    # Store original facing direction - if sprite.flip_h is false, NPC faces right
    # If sprite.flip_h is true, NPC faces left
    original_facing_right = not sprite.flip_h
    original_position = global_position  # Store original position
    
    # Connect to dialog finished signal to return to original direction
    DialogManager.dialog_finished.connect(_on_dialog_finished)

# Function to determine if player is in front or behind NPC
func is_player_behind_npc(player: Node2D) -> bool:
    # Use original facing direction
    var npc_facing_right = original_facing_right
    var player_to_npc = player.global_position - global_position
    
    # CORRECTED LOGIC:
    # If NPC faces RIGHT and player is to the RIGHT, player is BEHIND
    # If NPC faces LEFT and player is to the LEFT, player is BEHIND
    # If NPC faces RIGHT and player is to the LEFT, player is IN FRONT
    # If NPC faces LEFT and player is to the RIGHT, player is IN FRONT
    if npc_facing_right and player_to_npc.x > 0:
        return true
    elif not npc_facing_right and player_to_npc.x < 0:
        return true
    else:
        return false

# Function to turn NPC towards player
func turn_towards_player(player: Node2D) -> void:
    var player_to_npc = player.global_position - global_position
    # To face the player, NPC should face the OPPOSITE direction of where player is relative to NPC
    var should_face_right = player_to_npc.x < 0  # If player is to the left, NPC should face right
    
    # Add slight upward rotation when turning
    var tween = create_tween()
    tween.tween_property(sprite, "rotation_degrees", -5.0, 0.1)  # Slight upward tilt
    tween.tween_property(sprite, "rotation_degrees", 0.0, 0.1)   # Return to normal
    
    sprite.flip_h = not should_face_right
    is_turned_towards_player = true

# Function to return to original direction
func return_to_original_direction() -> void:
    sprite.flip_h = not original_facing_right
    is_turned_towards_player = false

# Function to start bobbing animation during dialog
func start_bobbing_animation() -> void:
    if bobbing_tween:
        bobbing_tween.kill()  # Stop any existing bobbing
    
    bobbing_tween = create_tween()
    bobbing_tween.set_loops()  # Loop infinitely
    bobbing_tween.tween_property(self, "position:y", original_position.y - 3.0, 0.5)  # Move up
    bobbing_tween.tween_property(self, "position:y", original_position.y + 3.0, 0.5)  # Move down
    bobbing_tween.tween_property(self, "position:y", original_position.y, 0.5)       # Return to center

# Function to stop bobbing animation
func stop_bobbing_animation() -> void:
    if bobbing_tween:
        bobbing_tween.kill()
        bobbing_tween = null

# Function to return to original position and then do tilt up animation
func return_to_original_position_and_tilt() -> void:
    var tween = create_tween()
    
    # First: Return to original position
    tween.tween_property(self, "global_position", original_position, 0.3)
    
    # Then: Do tilt up animation in original position
    tween.tween_property(sprite, "rotation_degrees", -8.0, 0.2)  # Tilt up more than before
    tween.tween_property(sprite, "rotation_degrees", 0.0, 0.3)   # Return to normal

func _on_interact():
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.can_freeze = true   # allow freezing only after pressing E
        
        # Turn towards player only if they are behind the NPC
        if is_player_behind_npc(player):
            turn_towards_player(player)
    
    # Start bobbing animation during dialog
    start_bobbing_animation()
    
    DialogManager.start_dialog(global_position, lines, speech_sound)

func _on_dialog_finished() -> void:
    # Stop bobbing animation
    stop_bobbing_animation()
    
    # Return to original direction and position when dialog ends
    if is_turned_towards_player:
        return_to_original_direction()
    
    # Return to original position, then do tilt up animation
    return_to_original_position_and_tilt()
