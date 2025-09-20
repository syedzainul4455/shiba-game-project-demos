extends CharacterBody2D

signal healthChanged(currentHealth: int)

@export var speed: float = 300.0
@export var jump_velocity: float = -450.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5
@export var max_jumps: int = 2

@export var maxHealth: int = 4
@export var invincible_time: float = 1.2

var currentHealth: int = 0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dim: ColorRect = $"../Dim"

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var spawn_position: Vector2 = Vector2.ZERO
var is_dead: bool = false
var is_dying: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_dir: float = 0.0
var jumps_left: int = 0
var force_drop_timer: float = 0.0
var enemy_stomps_taken: int = 0

var fall_timer: float = 0.0
var max_fall_time: float = 5.0
var is_fall_frozen: bool = false
var fall_freeze_duration: float = 0.35

var is_invincible: bool = false

# Freeze control when NPC dialog is active

# Freeze control when NPC dialog is active
var freeze_for_npc_dialog: bool = false
# Store the NPC node to face during dialog
var dialog_npc: Node = null


var was_dialog_active: bool = false
# Timer for auto-heal
var heal_timer: Timer

func _ready() -> void:
    currentHealth = maxHealth
    spawn_position = global_position
    jumps_left = max_jumps
    add_to_group("player")
    DialogManager.dialog_finished.connect(_on_dialog_finished)
    if dim:
        dim.color.a = 0.0
    emit_signal("healthChanged", currentHealth)

    # Start heal timer (every 120 seconds)
    heal_timer = Timer.new()
    heal_timer.wait_time = 120.0
    heal_timer.one_shot = false
    heal_timer.autostart = true
    add_child(heal_timer)
    heal_timer.timeout.connect(_on_heal_timer_timeout)

func _on_heal_timer_timeout() -> void:
    if currentHealth < maxHealth:
        heal(1)

func _physics_process(delta: float) -> void:
    if is_fall_frozen:
        velocity = Vector2.ZERO
        if anim_sprite and not is_dying:
            anim_sprite.play("idle")
        move_and_slide()
        return
    if is_dying:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    var dialog_active: bool = DialogManager.is_dialog_active
    if freeze_for_npc_dialog:
        # Block all input/actions, but allow gravity until landed
        if not is_on_floor():
            # Only apply gravity, ignore all input
            velocity.x = 0
            velocity.y += gravity * delta
            move_and_slide()
            return
        # On ground: freeze completely
        velocity = Vector2.ZERO
        if anim_sprite:
            anim_sprite.play("running")
            if dialog_npc:
                var npc_pos = dialog_npc.global_position if "global_position" in dialog_npc else dialog_npc.get_global_position()
                anim_sprite.flip_h = global_position.x > npc_pos.x
        move_and_slide()
        return
    elif dialog_active:
        # When dialog is active, allow gravity so player comes down if in air, block all input
        if not is_on_floor():
            velocity.x = 0
            velocity.y += gravity * delta
            move_and_slide()
            return
        velocity = Vector2.ZERO
        if anim_sprite:
            anim_sprite.play("running")
        move_and_slide()
        return

    if is_dashing:
        dash_timer -= delta
        velocity.x = dash_dir * dash_speed
        velocity.y = 0.0
        if anim_sprite and anim_sprite.animation != "dash":
            anim_sprite.play("dash")
        move_and_slide()
        if dash_timer <= 0.0:
            is_dashing = false
            dash_cooldown_timer = dash_cooldown
        return

    if dash_cooldown_timer > 0.0:
        dash_cooldown_timer -= delta

    if force_drop_timer > 0.0:
        force_drop_timer = max(force_drop_timer - delta, 0.0)
        velocity.y = max(velocity.y, 650.0)

    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        jumps_left = max_jumps

    if not is_on_floor():
        fall_timer += delta
        if fall_timer >= max_fall_time and not is_fall_frozen and not is_dead:
            is_fall_frozen = true
            velocity = Vector2.ZERO
            if anim_sprite: anim_sprite.play("idle")
            call_deferred("_handle_fall_freeze_and_die")
            return
    else:
        fall_timer = 0.0
        is_fall_frozen = false

    var input_dir: float = 0.0
    if Input.is_action_pressed("move_left"):
        input_dir -= 1.0
    if Input.is_action_pressed("move_right"):
        input_dir += 1.0
    velocity.x = input_dir * speed

    # Only flip based on input if not frozen for dialog
    if input_dir != 0 and anim_sprite:
        if freeze_for_npc_dialog:
            # Always keep facing the NPC (direction set in freeze_for_npc_dialog_start)
            pass
        else:
            anim_sprite.flip_h = input_dir < 0

    if Input.is_action_just_pressed("jump") and jumps_left > 0 and not is_dashing:
        AudioController.play_jump()
        AudioController.stop_walking()
        velocity.y = jump_velocity
        jumps_left -= 1

    if Input.is_action_pressed("move_down") and is_on_floor():
        position.y += 2.0

    if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and input_dir != 0.0 and not is_fall_frozen:
        start_dash(input_dir)

    move_and_slide()

    if global_position.y > 1000.0:
        # Instantly set health to 0, update hearts, and die/respawn
        currentHealth = 0
        emit_signal("healthChanged", currentHealth)
        die()

    if not is_dying:
        if not is_on_floor():
            if anim_sprite: anim_sprite.play("jumping")
            AudioController.stop_walking()
        else:
            if input_dir == 0:
                if anim_sprite: anim_sprite.play("idle")
                AudioController.stop_walking()
            else:
                if anim_sprite: anim_sprite.play("running")
                AudioController.start_walking()

func _process(_delta: float) -> void:
    var dialog_active: bool = DialogManager.is_dialog_active

    if dialog_active and not was_dialog_active:
        _on_dialog_started()
    elif not dialog_active and was_dialog_active:
        _on_dialog_finished()

    was_dialog_active = dialog_active

    if Input.is_action_just_pressed("ui_cancel"):
        if not dialog_active:
            go_to_main_menu()

func _unhandled_input(event: InputEvent) -> void:
    var dialog_active: bool = DialogManager.is_dialog_active
    if dialog_active:
        if event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
            if get_viewport():
                get_viewport().set_input_as_handled()

func _handle_fall_freeze_and_die() -> void:
    await get_tree().create_timer(float(fall_freeze_duration)).timeout
    if is_fall_frozen and not is_dead:
        die()

func take_damage(damage: int) -> void:
    if is_dead or is_invincible:
        return

    currentHealth -= damage
    currentHealth = max(currentHealth, 0)
    emit_signal("healthChanged", currentHealth)

    if currentHealth <= 0:
        die()
    else:
        start_invincibility()

func heal(amount: int) -> void:
    currentHealth = min(currentHealth + amount, maxHealth)
    emit_signal("healthChanged", currentHealth)

func start_invincibility() -> void:
    if is_invincible:
        return
    is_invincible = true

    var t_total: float = max(0.0, float(invincible_time))
    var elapsed: float = 0.0
    var blink_interval: float = 0.12
    while elapsed < t_total:
        if anim_sprite: anim_sprite.visible = false
        await get_tree().create_timer(blink_interval).timeout
        elapsed += blink_interval
        if elapsed >= t_total:
            break
        if anim_sprite: anim_sprite.visible = true
        await get_tree().create_timer(blink_interval).timeout
        elapsed += blink_interval

    is_invincible = false
    if anim_sprite: anim_sprite.visible = true

func start_dash(dir: float) -> void:
    is_dashing = true
    dash_timer = dash_duration
    dash_dir = dir
    velocity = Vector2(dash_dir * dash_speed, 0.0)

    if anim_sprite:
        # Only flip if not frozen for dialog
        if not freeze_for_npc_dialog:
            anim_sprite.flip_h = dash_dir < 0
        anim_sprite.play("dash")
        AudioController.play_dash()

func die() -> void:
    if is_dead or is_dying:
        return
    is_dead = true
    is_dying = true
    velocity = Vector2.ZERO

    # Play death animation and block all others
    if anim_sprite:
        anim_sprite.visible = true # Ensure visible before death
        # Only flip to face enemy if not frozen for dialog
        if not freeze_for_npc_dialog:
            var enemy = get_tree().get_first_node_in_group("Enemies")
            if enemy:
                if enemy.global_position.x < global_position.x:
                    anim_sprite.flip_h = true # Face left
                    print("[Death] Enemy is left. Player flip_h = true (face left)")
                else:
                    anim_sprite.flip_h = false # Face right
                    print("[Death] Enemy is right. Player flip_h = false (face right)")
            else:
                anim_sprite.flip_h = false # Default to face right if no enemy found
                print("[Death] No enemy found. Player set flip_h = false (face right)")
        anim_sprite.sprite_frames.set_animation_loop("death", false)
        anim_sprite.play("death")

    # Instantly fade in dim if present (optional, can be removed if not needed)
    if dim:
        dim.color.a = 1.0

    # Wait for death animation to finish (or fallback to 0.9s if not found)
    var death_anim_length = 0.7
    if anim_sprite and anim_sprite.sprite_frames.has_animation("death"):
        var frames = anim_sprite.sprite_frames
        var frame_count = frames.get_frame_count("death")
        var anim_speed = frames.get_animation_speed("death")
        if anim_speed > 0:
            death_anim_length = (frame_count / float(anim_speed)) + 0.05
    await get_tree().create_timer(death_anim_length).timeout

    hide()
    respawn()
    is_dying = false

    # Instantly fade out dim if present (optional, can be removed if not needed)
    if dim:
        dim.color.a = 0.0

func force_drop(duration: float = 0.06) -> void:
    force_drop_timer = max(force_drop_timer, duration)

func respawn() -> void:
    global_position = spawn_position
    velocity = Vector2.ZERO
    show()
    if anim_sprite:
        anim_sprite.visible = true
    is_dead = false
    jumps_left = max_jumps
    enemy_stomps_taken = 0
    fall_timer = 0.0
    is_fall_frozen = false
    currentHealth = maxHealth
    emit_signal("healthChanged", currentHealth)
    start_invincibility()

func _on_dialog_started() -> void:
    # This is called for any dialog, but we only want to freeze for NPC dialog
    pass

func freeze_for_npc_dialog_start(npc: Node = null):
    print("[DEBUG] freeze_for_npc_dialog_start CALLED", " npc:", npc)
    freeze_for_npc_dialog = true
    dialog_npc = npc
    velocity = Vector2.ZERO
    if anim_sprite:
        anim_sprite.play("running")
        if npc:
            var npc_pos = npc.global_position if "global_position" in npc else npc.get_global_position()
            anim_sprite.flip_h = global_position.x > npc_pos.x
            print("[DEBUG] Dialog Start: Player X:", global_position.x, " NPC X:", npc_pos.x, " flip_h:", anim_sprite.flip_h)
        else:
            anim_sprite.flip_h = false
            print("[DEBUG] Dialog Start: Player X:", global_position.x, " NPC: None", " flip_h:", anim_sprite.flip_h)

func freeze_for_npc_dialog_end():
    freeze_for_npc_dialog = false
    dialog_npc = null

func _on_dialog_finished() -> void:
    pass

func go_to_main_menu() -> void:
    if not dim:
        if DialogManager.is_dialog_active:
            if ("cancel" in DialogManager): DialogManager.cancel()
            elif ("force_close" in DialogManager): DialogManager.force_close()
            elif ("hide" in DialogManager): DialogManager.hide()
            if ("dialog_finished" in DialogManager): DialogManager.dialog_finished.emit()
            DialogManager.is_dialog_active = false
        if "start_loading" in LoadingScreen:
            LoadingScreen.start_loading("res://scenes/Main_Menu.tscn")
        else:
            get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")
        return

    var tween: Tween = create_tween()
    tween.tween_property(dim, "color:a", 1.0, 0.5)
    await tween.finished
    if DialogManager.is_dialog_active:
        if ("cancel" in DialogManager): DialogManager.cancel()
        elif ("force_close" in DialogManager): DialogManager.force_close()
        elif ("hide" in DialogManager): DialogManager.hide()
        if ("dialog_finished" in DialogManager): DialogManager.dialog_finished.emit()
        DialogManager.is_dialog_active = false
    if "start_loading" in LoadingScreen:
        LoadingScreen.start_loading("res://scenes/Main_Menu.tscn")
    else:
        get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")
