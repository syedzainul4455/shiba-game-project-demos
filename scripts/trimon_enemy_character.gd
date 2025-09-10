extends CharacterBody2D

signal defeated

@export var move_speed := 120.0
@export var gravity := 1800.0
@export var jump_force := -560.0
@export var chase_accel := 900.0
@export var max_chase_speed := 160.0
@export var attack_range := 350.0
@export var stomp_bounce := -420.0
@export var dash_speed := 450.0
@export var dash_duration := 0.22
@export var reflex_cooldown := 0.8

var cooldown_timer := 0.0
var stuck_timer := 0.0
var max_stuck_time := 0.85

var dash_time_left := 0.0
var spawn_position: Vector2

var enemy_stomp_hits := 0               # Player stomps needed: 3 to kill enemy (reduced from 5)
var player_hits_by_enemy := 0           # Enemy stomps on player: 4 to kill player
var stomp_immunity_time := 0.05         # Prevent multi-stomp in one frame (reduced)
var stomp_immunity_left := 0.0

var prev_player_dead := false
var original_flip_h := false
var is_dead_enemy := false

# Sound tracking variables (removed footsteps, keeping only jump sounds)

# Double-jump attack control
var queued_second_jump := false
var second_jump_window := 0.35
var second_jump_timer := 0.0

# Platform bounds and cliff detection
@export var platform_left_x: float = -1e9
@export var platform_right_x: float = 1e9
@export var cliff_check_distance: float = 16.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

# One-time dialog before aggression
var has_spoken_to_player := false
const intro_lines: Array[String] = [
    "You dare enter my platform?",
    "Let's see how high you can bounce!"
]

func _ready() -> void:
    anim.play("idle")
    spawn_position = global_position
    if anim:
        original_flip_h = anim.flip_h

func _physics_process(delta: float) -> void:
    if not player:
        return

    # Track player respawn
    if "is_dead" in player and player.is_dead and not prev_player_dead:
        prev_player_dead = true
    if "is_dead" in player and not player.is_dead and prev_player_dead:
        _respawn()
        prev_player_dead = false

    cooldown_timer = max(cooldown_timer - delta, 0.0)
    stomp_immunity_left = max(stomp_immunity_left - delta, 0.0)
    second_jump_timer = max(second_jump_timer - delta, 0.0)

    # Gravity unless dashing
    if dash_time_left <= 0.0:
        velocity.y += gravity * delta
    else:
        dash_time_left -= delta

    # Smart chase
    var dir_x: float = sign(player.global_position.x - global_position.x)
    var distance: float = abs(player.global_position.x - global_position.x)
    var same_platform: bool = abs(player.global_position.y - global_position.y) < 96.0

    # Intro dialog
    if not has_spoken_to_player and same_platform and distance < attack_range:
        if not DialogManager.is_dialog_active:
            if player and "can_freeze" in player:
                player.can_freeze = true
            DialogManager.start_dialog(global_position, intro_lines, null)
            has_spoken_to_player = true

    if DialogManager.is_dialog_active:
        _play_idle_or_run()
        move_and_slide()
        return

    if is_dead_enemy:
        move_and_slide()
        return

    # Stay inside platform
    if global_position.x < platform_left_x:
        global_position.x = platform_left_x
        velocity.x = abs(velocity.x)
    elif global_position.x > platform_right_x:
        global_position.x = platform_right_x
        velocity.x = -abs(velocity.x)

    # Attacks
    if same_platform and is_on_floor() and dash_time_left <= 0.0 and distance < attack_range and cooldown_timer <= 0.0:
        var vertical_diff := player.global_position.y - global_position.y
        if abs(vertical_diff) < 40.0:
            _start_dash(dir_x)
        else:
            _jump_attack(dir_x)
        cooldown_timer = reflex_cooldown
        if not is_on_floor():
            queued_second_jump = true
            second_jump_timer = second_jump_window

    if queued_second_jump and is_on_floor() and second_jump_timer > 0.0 and cooldown_timer <= 0.0 and same_platform and distance < attack_range:
        _jump_attack(dir_x)
        queued_second_jump = false
        cooldown_timer = reflex_cooldown

    if same_platform and dash_time_left <= 0.0 and distance < attack_range:
        var target_speed: float = dir_x * max_chase_speed
        velocity.x = move_toward(velocity.x, target_speed, chase_accel * delta)
    else:
        var delta_x: float = spawn_position.x - global_position.x
        var patrol_dir: float = sign(delta_x)
        if abs(delta_x) < 6.0:
            patrol_dir = 0.0
        var patrol_speed: float = 120.0
        velocity.x = move_toward(velocity.x, patrol_dir * patrol_speed, (chase_accel * 0.5) * delta)

    move_and_slide()

    # Handle collisions
    _handle_player_contact()
    _play_idle_or_run()

    # Unstuck jump - only when player is close
    if is_on_floor() and abs(velocity.x) < 5.0 and distance < attack_range:
        stuck_timer += delta
        if stuck_timer >= max_stuck_time:
            velocity.y = jump_force * 0.6
            stuck_timer = 0.0
            # Play jump sound for unstuck jump
            if AudioController:
                AudioController.play_jump()
    else:
        stuck_timer = 0.0


func _start_dash(dir_x: float) -> void:
    dash_time_left = dash_duration
    velocity.x = dir_x * dash_speed
    velocity.y = 0.0
    anim.play("running")

func _jump_attack(dir_x: float) -> void:
    if not is_on_floor():
        return
    velocity.x = dir_x * max(move_speed, max_chase_speed)
    velocity.y = jump_force
    anim.play("running")
    # Play jump sound
    if AudioController:
        AudioController.play_jump()

func _play_idle_or_run() -> void:
    # Animation only - no footsteps sounds
    if is_on_floor():
        if abs(velocity.x) > 5.0:
            anim.play("running")
        else:
            anim.play("idle")
    else:
        anim.play("running")

# ✅ Fixed stomp logic
func _handle_player_contact() -> void:
    if not player:
        return

    var horizontal_near: bool = abs(player.global_position.x - global_position.x) < 32.0
    var vertical_near: bool = abs(player.global_position.y - global_position.y) < 42.0
    if not (horizontal_near and vertical_near):
        return

    var player_above: bool = player.global_position.y < global_position.y - 8.0
    var player_falling: bool = ("velocity" in player and player.velocity.y > 60.0)
    var enemy_falling: bool = velocity.y > 0.0

    if player_above and player_falling and stomp_immunity_left <= 0.0:
        stomp_immunity_left = stomp_immunity_time
        enemy_stomp_hits += 1
        print("Enemy stomp hits: ", enemy_stomp_hits)  # Debug info

        if "velocity" in player:
            player.velocity.y = stomp_bounce

        # Kick player off enemy's head
        player.global_position.y = global_position.y - 48.0
        if "force_drop" in player:
            player.force_drop(0.15)

        # Each single jump counts as one hit - enemy dies after 3 jumps
        if enemy_stomp_hits >= 3:
            print("Enemy should die now!")  # Debug info
            is_dead_enemy = true
            hide()
            emit_signal("defeated")
    elif player_above and not player_falling:
        # Player standing → enemy does double jump to make player fall
        if is_on_floor() and cooldown_timer <= 0.0:
            # First jump
            velocity.y = jump_force
            # Queue second jump
            queued_second_jump = true
            second_jump_timer = second_jump_window
            cooldown_timer = reflex_cooldown
            # Play jump sound
            if AudioController:
                AudioController.play_jump()
            print("Enemy double jump to shake off player!")
    elif enemy_falling and not player_above:
        if stomp_immunity_left <= 0.0 and velocity.y > 200.0:
            stomp_immunity_left = stomp_immunity_time
            player_hits_by_enemy += 1
            if player_hits_by_enemy >= 4:
                if player.has_method("die"):
                    player.die()

func _respawn() -> void:
    global_position = spawn_position
    velocity = Vector2.ZERO
    enemy_stomp_hits = 0
    player_hits_by_enemy = 0
    dash_time_left = 0.0
    cooldown_timer = 0.0
    stuck_timer = 0.0
    # Reset variables
    anim.play("idle")
    if anim:
        anim.flip_h = original_flip_h
    has_spoken_to_player = false
    is_dead_enemy = false
    show()
