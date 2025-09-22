extends Node2D
# Interaction integration
@onready var interaction_area: Area2D = $InteractionArea

@onready var spinwheel_sprite: Sprite2D = $spinwheel
@onready var stopper_sprite: Sprite2D = $stopper
@onready var start_button: Button = $start
@onready var label: Label = $Label

var chances_label: Label

# Wheel geometry
var wheel_center: Vector2
var wheel_radius: float
var original_rotation: float = 0.0

## Sector information
var sectors: Array = []
var sector_actions: Array = ["Overall Boost", "Attack", "Health/Damage", "Speed/Dash"]
var sector_colors: Array = [Color.GREEN, Color.YELLOW, Color.BLUE, Color.ORANGE]

var spinning := false
var spin_speed := 0.0
var spin_deceleration := 0.0
var has_spun_this_life := false
var last_player_alive: bool = false

# Spin chances
var max_spin_chances := 3
var spin_chances_left := 3


# Proximity detection
var player_in_area: bool = false
var player_node: Node = null

# Preload player script for early access
var PlayerScript = preload("res://scripts/player.gd")


func _ready() -> void:
    # Connect signals for interaction area
    if interaction_area:
        interaction_area.body_entered.connect(_on_interaction_area_entered)
        interaction_area.body_exited.connect(_on_interaction_area_exited)
func _on_interaction_area_entered(body):
    if body.is_in_group("player"):
        player_in_area = true
        print("[DEBUG] Player entered interaction area.")

func _on_interaction_area_exited(body):
    if body.is_in_group("player"):
        player_in_area = false
        print("[DEBUG] Player exited interaction area.")
    print("[DEBUG] Spinwheel _ready called. Node active and script running.")
    # Connect button
    if start_button:
        start_button.pressed.connect(_on_start_button_pressed)

    # Get reference to chances label (node named 'Label' in scene)
    chances_label = $Label if has_node("Label") else null
    if chances_label:
        var font_file = load("res://Gagalin-Regular.ttf")
        if font_file:
            chances_label.add_theme_font_override("font", font_file)
            chances_label.add_theme_font_size_override("font_size", 80)
    update_chances_label()
    print("[DEBUG] _ready: spin_chances_left:", spin_chances_left)

    # Initialize wheel properties after scene is loaded
    call_deferred("initialize_wheel")

    # Store original rotation for robust reset
    if spinwheel_sprite:
        original_rotation = spinwheel_sprite.rotation
# Robust spinwheel reset function
func reset_spinwheel():
    print("[DEBUG] reset_spinwheel called.")
    has_spun_this_life = false
    spin_chances_left = max_spin_chances
    print("[DEBUG] spin_chances_left reset to:", spin_chances_left)
    update_chances_label()
    if chances_label:
        chances_label.text = "Chances left: %d" % spin_chances_left
        print("[DEBUG] reset_spinwheel: chances_label updated to:", chances_label.text)
    if spinwheel_sprite:
        spinwheel_sprite.rotation = original_rotation # Robust reset to original position
        print("[DEBUG] Spinwheel reset to original rotation.")
    else:
        print("[DEBUG] Spinwheel sprite not found during reset.")

    # Setup interaction area for InteractionManager system
    if interaction_area:
        interaction_area.action_name = "spinwheel"
        interaction_area.interact = func():
            _on_interact()

func initialize_wheel():
    sectors.clear()
    # Sector angles based on image (clockwise, starting from top)
    # 0: White/Grey: 315° to 45° (wraps around)
    # 1: Blue: 45° to 135°
    # 2: Pink: 135° to 225°
    # 3: Purple: 225° to 315°
    sectors.append({"start_angle": deg_to_rad(315), "end_angle": deg_to_rad(45)})   # White/Grey
    sectors.append({"start_angle": deg_to_rad(45), "end_angle": deg_to_rad(135)})   # Blue
    sectors.append({"start_angle": deg_to_rad(135), "end_angle": deg_to_rad(225)}) # Pink
    sectors.append({"start_angle": deg_to_rad(225), "end_angle": deg_to_rad(315)}) # Purple
    # Set wheel center and radius for drawing
    if spinwheel_sprite and spinwheel_sprite.texture:
        wheel_center = spinwheel_sprite.position
        wheel_radius = float(spinwheel_sprite.texture.get_width()) / 2.0
func _on_interact():
    print("[DEBUG] _on_interact called. spinning:", spinning, "alive:", is_player_alive(), "chances:", spin_chances_left)
    if not spinning and is_player_alive() and spin_chances_left > 0:
        # Try to find player if not set
        if not player_node:
            var players = get_tree().get_nodes_in_group("player")
            print("[DEBUG] Found players:", players)
            if players.size() > 0:
                player_node = players[0]
        # Always cancel previous boosts before spinning again
        if player_node and player_node.has_method("cancel_all_boosts"):
            print("[DEBUG] Cancelling all boosts on player before spinning.")
            player_node.cancel_all_boosts()
        spinning = true
        spin_speed = randf_range(8.0, 14.0) # Random initial speed
        spin_deceleration = randf_range(1.2, 2.5) # Random deceleration
        print("[DEBUG] Started spinning. spin_speed:", spin_speed, "deceleration:", spin_deceleration)
        spin_chances_left = max(0, spin_chances_left - 1)
        update_chances_label()
    elif spin_chances_left <= 0:
        print("[DEBUG] No spin chances left. Ignoring spin input.")

func _process(delta: float) -> void:
    if spinning and spinwheel_sprite:
        print("[DEBUG] _process running. spin_speed:", spin_speed, "rotation:", spinwheel_sprite.rotation)
        if spin_speed > 0.0:
            spinwheel_sprite.rotation += spin_speed * delta
            spin_speed = max(0.0, spin_speed - spin_deceleration * delta)
            # Real-time sector detection while spinning (for debugging)
            var current_angle = fmod(spinwheel_sprite.rotation, 2 * PI)
            if current_angle < 0:
                current_angle += 2 * PI
            var _sector = get_sector_from_angle(current_angle)
            # No debug label update
        else:
            print("[DEBUG] Stopping spin.")
            spinning = false
            spin_speed = 0.0
            _on_spin_stopped()
    # Debug input and area detection
    # Track last known alive state for player
    if player_node:
        var alive_now = is_player_alive()
        if last_player_alive == false and alive_now == true:
            print("[DEBUG] Player respawn detected. Calling reset_spinwheel.")
            reset_spinwheel()
        last_player_alive = alive_now
    # Handle G key input for spinning
    if player_in_area and Input.is_action_just_pressed("interact") and not spinning and is_player_alive() and spin_chances_left > 0:
        # Try to find player if not set
        if not player_node:
            var players = get_tree().get_nodes_in_group("player")
            if players.size() > 0:
                player_node = players[0]
        # End any previous boost immediately before spinning again
        if player_node and player_node.has_method("cancel_all_boosts"):
            player_node.cancel_all_boosts()
        spinning = true
        spin_speed = randf_range(8.0, 14.0) # Random initial speed
        spin_deceleration = randf_range(1.2, 2.5) # Random deceleration
        spin_chances_left = max(0, spin_chances_left - 1)
        update_chances_label()
    elif player_in_area and Input.is_action_just_pressed("interact") and spin_chances_left <= 0:
        print("[DEBUG] No spin chances left. Ignoring spin input.")
    queue_redraw()

func _on_spin_stopped() -> void:
    # Get the final rotation of the wheel
    if spinwheel_sprite:
        var final_rotation = fmod(spinwheel_sprite.rotation, 2 * PI)
        if final_rotation < 0:
            final_rotation += 2 * PI

        # The stopper points straight up (y axis negative), so sector is at angle 3*PI/2
        var stopper_angle = 3 * PI / 2
        var wheel_angle = fmod(final_rotation, 2 * PI)
        var pointer_angle = fmod(wheel_angle + stopper_angle, 2 * PI)

        print("[DEBUG] Spin stopped. Wheel angle:", wheel_angle, "Pointer angle:", pointer_angle)
        for i in range(sectors.size()):
            var sector = sectors[i]
            print("[DEBUG] Sector", i, "start:", sector.start_angle, "end:", sector.end_angle)

        var sector_index = get_sector_from_angle(pointer_angle)
        print("[DEBUG] Selected sector index:", sector_index)
        if sector_index >= 0 and sector_index < sector_actions.size():
            handle_sector_action(sector_index)
        else:
            print("Unknown sector! Angle:", pointer_angle)

func get_sector_from_angle(angle: float) -> int:
    # Find which sector contains this angle
    for i in range(sectors.size()):
        var sector = sectors[i]
        var start_angle = sector.start_angle
        var end_angle = sector.end_angle
        # Normalize angles to [0, 2*PI]
        var norm_pointer = fmod(angle + TAU, TAU)
        var norm_start = fmod(start_angle + TAU, TAU)
        var norm_end = fmod(end_angle + TAU, TAU)
        # Handle wrap-around sectors
        var epsilon = 0.0001
        if norm_end < norm_start:
            if norm_pointer >= norm_start or norm_pointer <= norm_end + epsilon:
                print("[DEBUG] Sector detected (wrap):", i, "Pointer:", norm_pointer, "Start:", norm_start, "End:", norm_end)
                return i
        else:
            if norm_pointer >= norm_start and norm_pointer <= norm_end + epsilon:
                print("[DEBUG] Sector detected:", i, "Pointer:", norm_pointer, "Start:", norm_start, "End:", norm_end)
                return i
    print("[DEBUG] No sector found! Pointer:", angle)
    return -1  # No sector found

func handle_sector_action(sector: int) -> void:
    if not player_node:
        print("No player to apply action!")
        return
    var duration = 180 # 3 minutes
    # Cancel any previous boost timers (overwrite)
    if player_node:
        if player_node.has_method("cancel_all_boosts"):
            player_node.cancel_all_boosts()
    print("[DEBUG] handle_sector_action called for sector:", sector)
    match sector:
        0: # White/Grey: Overall performance boost
            print("Overall performance boost triggered!")
            if player_node.has_method("apply_overall_boost"):
                player_node.apply_overall_boost(duration)
                blink_player()
            else:
                print("[DEBUG] Player missing apply_overall_boost method.")
        1: # Red: Attack increase
            print("Attack boost triggered!")
            if player_node.has_method("apply_attack_boost"):
                player_node.apply_attack_boost(duration)
                blink_player()
            else:
                print("[DEBUG] Player missing apply_attack_boost method.")
        2: # Blue: Health increase & damage reduction
            print("Health/Damage boost triggered!")
            if player_node.has_method("apply_health_damage_boost"):
                player_node.apply_health_damage_boost(duration)
                blink_player()
            else:
                print("[DEBUG] Player missing apply_health_damage_boost method.")
        3: # Purple: Speed & dash ability
            print("Speed/Dash boost triggered!")
            if player_node.has_method("apply_speed_dash_boost"):
                player_node.apply_speed_dash_boost(duration)
                blink_player()
            else:
                print("[DEBUG] Player missing apply_speed_dash_boost method.")
        _:
            print("Unknown sector! Sector index:", sector)

func blink_player():
    if player_node and player_node.has_node("AnimatedSprite2D"):
        var sprite = player_node.get_node("AnimatedSprite2D")
        var blink_times = 10
        var blink_interval = 0.1
        for i in range(blink_times):
            sprite.visible = false
            await get_tree().create_timer(blink_interval).timeout
            sprite.visible = true
            await get_tree().create_timer(blink_interval).timeout

func _on_start_button_pressed() -> void:
    if not spinning and is_player_alive() and spin_chances_left > 0:
        # Try to find player if not set
        if not player_node:
            var players = get_tree().get_nodes_in_group("player")
            if players.size() > 0:
                player_node = players[0]
        # Cancel previous boosts before spinning again
        if player_node and player_node.has_method("cancel_all_boosts"):
            player_node.cancel_all_boosts()
        if spin_chances_left > 0:
            spinning = true
            spin_speed = randf_range(8.0, 14.0) # Random initial speed
            spin_deceleration = randf_range(1.2, 2.5) # Random deceleration
            spin_chances_left = max(0, spin_chances_left - 1)
            update_chances_label()
# Utility to update the label with remaining chances
func update_chances_label():
    # Always clamp spin_chances_left between 0 and max_spin_chances
    spin_chances_left = clamp(spin_chances_left, 0, max_spin_chances)
    if chances_label:
        chances_label.text = "Chances left: %d" % spin_chances_left

# Utility function to check if the player is alive
func is_player_alive() -> bool:
    if player_node and player_node.has_method("is_alive"):
        return player_node.is_alive()
    # Default: allow spinning if no player node or method
    return true

# --- Player Action Implementations (for demonstration) ---
# These would normally be in the player script, but are included here for testing.
var speed_boost_active := false
var block_boost_active := false
var attack_boost_active := false
var overall_boost_active := false

func apply_speed_boost(duration: int):
    speed_boost_active = true
    if player_node and "speed" in player_node:
        print("[DEBUG] Speed stat before boost:", player_node.speed)
        player_node.speed += 10 # Example boost value
        print("[DEBUG] Speed stat after boost:", player_node.speed)
    print("Speed boost applied for %d seconds!" % duration)
    await get_tree().create_timer(duration).timeout
    speed_boost_active = false
    if player_node and "speed" in player_node:
        player_node.speed -= 10 # Remove boost after duration
        print("[DEBUG] Speed stat after boost ended:", player_node.speed)
    print("Speed boost ended.")

func apply_block_boost(duration: int):
    block_boost_active = true
    if player_node and "block" in player_node:
        print("[DEBUG] Block stat before boost:", player_node.block)
        player_node.block += 10 # Example boost value
        print("[DEBUG] Block stat after boost:", player_node.block)
    print("Block boost applied for %d seconds!" % duration)
    await get_tree().create_timer(duration).timeout
    block_boost_active = false
    if player_node and "block" in player_node:
        player_node.block -= 10 # Remove boost after duration
        print("[DEBUG] Block stat after boost ended:", player_node.block)
    print("Block boost ended.")

func apply_attack_boost(duration: int):
    attack_boost_active = true
    if player_node and "attack" in player_node:
        print("[DEBUG] Attack stat before boost:", player_node.attack)
        player_node.attack += 10 # Example boost value
        print("[DEBUG] Attack stat after boost:", player_node.attack)
    print("Attack boost applied for %d seconds!" % duration)
    await get_tree().create_timer(duration).timeout
    attack_boost_active = false
    if player_node and "attack" in player_node:
        player_node.attack -= 10 # Remove boost after duration
        print("[DEBUG] Attack stat after boost ended:", player_node.attack)
    print("Attack boost ended.")

func apply_overall_boost(duration: int):
    overall_boost_active = true
    print("[DEBUG] Overall stats before boost:")
    if player_node and "speed" in player_node:
        print("[DEBUG] Speed:", player_node.speed)
        player_node.speed += 10
        print("[DEBUG] Speed after boost:", player_node.speed)
    if player_node and "block" in player_node:
        print("[DEBUG] Block:", player_node.block)
        player_node.block += 10
        print("[DEBUG] Block after boost:", player_node.block)
    if player_node and "attack" in player_node:
        print("[DEBUG] Attack:", player_node.attack)
        player_node.attack += 10
        print("[DEBUG] Attack after boost:", player_node.attack)
    print("Overall boost applied for %d seconds!" % duration)
    await get_tree().create_timer(duration).timeout
    overall_boost_active = false
    print("[DEBUG] Overall stats after boost ended:")
    if player_node and "speed" in player_node:
        player_node.speed -= 10
        print("[DEBUG] Speed:", player_node.speed)
    if player_node and "block" in player_node:
        player_node.block -= 10
        print("[DEBUG] Block:", player_node.block)
    if player_node and "attack" in player_node:
        player_node.attack -= 10
        print("[DEBUG] Attack:", player_node.attack)
    print("Overall boost ended.")



func _draw():
    # Optionally draw wheel center (remove if unwanted)
    
    # Draw sector visualization
    if sectors.is_empty():
        return
        
    for i in range(sectors.size()):
        var sector = sectors[i]
        var start_angle = sector.start_angle
        var end_angle = sector.end_angle
        var color = sector_colors[i] if i < sector_colors.size() else Color.WHITE
        color.a = 0.3  # Semi-transparent
        
        # Handle sectors that wrap around from 2π to 0
        if end_angle < start_angle:
            # Draw two segments: one from start_angle to 2π, another from 0 to end_angle
            draw_sector_segment(start_angle, 2 * PI, color)
            draw_sector_segment(0, end_angle, color)
        else:
            # Normal case: draw the sector from start_angle to end_angle
            draw_sector_segment(start_angle, end_angle, color)

func draw_sector_segment(start_angle: float, end_angle: float, color: Color) -> void:
    var points = []
    var step_count = 20
    var step_angle = (end_angle - start_angle) / step_count
    
    # Create points for the sector segment
    for i in range(step_count + 1):
        var angle = start_angle + step_angle * i
        var x = wheel_center.x + cos(angle) * wheel_radius
        var y = wheel_center.y + sin(angle) * wheel_radius
        points.append(Vector2(x, y))
    
    # Draw the sector segment
    for i in range(points.size() - 1):
        var p1 = points[i]
        var p2 = points[i + 1]
        draw_line(p1, p2, color, 2.0)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_in_area = true
        player_node = body
        has_spun_this_life = false # Always reset spin flag when player enters
        # Do NOT reset spin chances on area enter
        update_chances_label()
        if spinwheel_sprite:
            spinwheel_sprite.rotation = randf_range(0, 2 * PI) # Randomize wheel position on entry
            print("[DEBUG] Spinwheel reset on area enter. Rotation:", spinwheel_sprite.rotation)
        # Connect to healthChanged signal if not already connected
        var callable = Callable(self, "_on_player_health_changed")
        if player_node.has_method("respawn") and not player_node.is_connected("healthChanged", callable):
            player_node.connect("healthChanged", callable)

func _on_player_health_changed(currentHealth: int) -> void:
    var died := false
    var respawned := false
    # Detect any type of death (health 0 or custom method)
    if player_node:
        if player_node.has_method("is_dead"):
            died = player_node.is_dead()
        elif player_node.has_method("are_all_hearts_frame_3"):
            died = player_node.are_all_hearts_frame_3()
        elif currentHealth == 0:
            died = true
        # Detect respawn (health == maxHealth)
        if currentHealth == player_node.maxHealth:
            respawned = true

    if died or respawned or (player_node and player_node.has_method("are_all_hearts_frame_3") and player_node.are_all_hearts_frame_3()):
        reset_spinwheel()
        # Reset all boosts on player death/respawn
        if player_node and player_node.has_method("cancel_all_boosts"):
            player_node.cancel_all_boosts()

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_in_area = false
        player_node = null
