extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -450.0
@export var dash_speed := 800.0
@export var dash_duration := 0.2
@export var dash_cooldown := 0.5
@export var max_jumps := 2   # double jump

var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
var spawn_position: Vector2
var is_dead := false
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_dir := 0.0
var jumps_left := 0

# Enemy combat accounting
var enemy_stomps_taken := 0     # die at 4
var force_drop_timer := 0.0

var can_freeze := false   # only true after interact

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dim: ColorRect = $"../Dim"   # fade overlay in Game scene


func _ready() -> void:
    spawn_position = global_position
    jumps_left = max_jumps

    # Listen to dialog finish signal
    DialogManager.dialog_finished.connect(_on_dialog_finished)

    # Ensure Dim starts invisible
    if dim:
        dim.color.a = 0.0


func _physics_process(delta: float) -> void:
    # Freeze during dialog
    if DialogManager.is_dialog_active and can_freeze:
        if is_on_floor():
            velocity = Vector2.ZERO
            anim_sprite.play("idle")
            return
        else:
            velocity.y += gravity * delta
            move_and_slide()
            return

    # Dash
    if is_dashing:
        dash_timer -= delta
        velocity.x = dash_dir * dash_speed
        velocity.y = 0.0
        move_and_slide()
        if dash_timer <= 0.0:
            is_dashing = false
            dash_cooldown_timer = dash_cooldown
        return

    if dash_cooldown_timer > 0.0:
        dash_cooldown_timer -= delta

    # Force-drop after stomps to avoid hovering above enemies
    if force_drop_timer > 0.0:
        force_drop_timer = max(force_drop_timer - delta, 0.0)
        velocity.y = max(velocity.y, 650.0)

    # Gravity
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        jumps_left = max_jumps

    # Movement
    var input_dir := 0.0
    if Input.is_action_pressed("move_left"):
        input_dir -= 1.0
    if Input.is_action_pressed("move_right"):
        input_dir += 1.0
    velocity.x = input_dir * speed

    # Flip sprite
    if input_dir != 0:
        anim_sprite.flip_h = input_dir < 0

    # Jump
    if Input.is_action_just_pressed("jump") and jumps_left > 0:
        if AudioController:
            AudioController.play_jump()
            AudioController.stop_walking()  # Stop walk sound when jumping
        velocity.y = jump_velocity
        jumps_left -= 1

    # Drop down
    if Input.is_action_pressed("move_down") and is_on_floor():
        position.y += 2.0

    # Dash
    if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and input_dir != 0.0:
        start_dash(input_dir)

    move_and_slide()

    # Respawn if falling out
    if global_position.y > 1000.0:
        die()

    # Animation and walk sound
    if not is_on_floor():
        anim_sprite.play("running") # TODO: change to jump/fall anim if you add
        if AudioController:
            AudioController.stop_walking()  # Stop walk sound when not on floor
    else:
        if input_dir == 0:
            anim_sprite.play("idle")
            if AudioController:
                AudioController.stop_walking()  # Stop walk sound when idle
        else:
            anim_sprite.play("running")
            if AudioController:
                AudioController.start_walking()  # Start walk sound when running on floor


func _process(delta: float) -> void:
    # Press Esc / Backspace / Q (all inside ui_cancel) — disabled during dialog
    if Input.is_action_just_pressed("ui_cancel"):
        if not DialogManager.is_dialog_active:
            go_to_main_menu()

# Block escape keys globally while dialog is active
func _unhandled_input(event: InputEvent) -> void:
    if DialogManager.is_dialog_active:
        if event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
            if get_viewport():
                get_viewport().set_input_as_handled()


# --- Helpers ---
func start_dash(dir: float) -> void:
    is_dashing = true
    dash_timer = dash_duration
    dash_dir = dir
    velocity = Vector2(dash_dir * dash_speed, 0.0)


func die() -> void:
    if is_dead:
        return
    is_dead = true
    can_freeze = false
    hide()
    velocity = Vector2.ZERO
    await get_tree().create_timer(0.3).timeout
    respawn()

func force_drop(duration: float = 0.06) -> void:
    force_drop_timer = max(force_drop_timer, duration)


func respawn() -> void:
    global_position = spawn_position
    velocity = Vector2.ZERO
    show()
    is_dead = false
    jumps_left = max_jumps
    enemy_stomps_taken = 0


func _on_dialog_finished() -> void:
    can_freeze = false


# --- Fade + return to main menu ---
func go_to_main_menu() -> void:
    if not dim:
        # Ensure any running dialog is closed before switching scenes
        if Engine.has_singleton("DialogManager"):
            var dm = DialogManager
            if ("is_dialog_active" in dm) and dm.is_dialog_active:
                if ("cancel" in dm):
                    dm.cancel()
                elif ("force_close" in dm):
                    dm.force_close()
                elif ("hide" in dm):
                    dm.hide()
                if ("dialog_finished" in dm):
                    dm.dialog_finished.emit()
                dm.is_dialog_active = false
        get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn" )
        return

    var tween := create_tween()
    tween.tween_property(dim, "color:a", 1.0, 0.5)  # fade to black in 0.5s
    await tween.finished
    # Ensure any running dialog is closed before switching scenes
    if Engine.has_singleton("DialogManager"):
        var dm2 = DialogManager
        if ("is_dialog_active" in dm2) and dm2.is_dialog_active:
            if ("cancel" in dm2):
                dm2.cancel()
            elif ("force_close" in dm2):
                dm2.force_close()
            elif ("hide" in dm2):
                dm2.hide()
            if ("dialog_finished" in dm2):
                dm2.dialog_finished.emit()
            dm2.is_dialog_active = false
    get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn") # <- change path if needed
