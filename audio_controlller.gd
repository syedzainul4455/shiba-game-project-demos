extends Node

# Audio controller singleton for managing game sounds
# This script is attached to the AudioController scene which is loaded as AutoLoad


# Reference to existing AudioStreamPlayer nodes in the scene
@onready var footsteps: AudioStreamPlayer = $footsteps
@onready var jump: AudioStreamPlayer = $jump
@onready var dash: AudioStreamPlayer = $dash
# Add new AudioStreamPlayers for hit and death
@onready var hit: AudioStreamPlayer = $hit
@onready var death: AudioStreamPlayer = $death

# Walk sound timing variables
var walk_timer: float = 0.0
var walk_interval: float = 0.3  # Time between walk sound plays
var is_walking: bool = false

func _ready() -> void:
    # Set up walk sound properties
    footsteps.volume_db = 12  # Adjust volume as needed
    footsteps.pitch_scale = 1.0
    
    # Set up jump sound properties
    jump.volume_db = 3   # Lower volume for jump sounds
    jump.pitch_scale = 1.0
    
    # Load audio files (you'll need to add these audio files to your project)
    # footsteps.stream = preload("res://audio/walk.wav")
    # jump.stream = preload("res://audio/jump.wav")

    # Set up hit and death sound properties
    if hit:
        hit.volume_db = 0
        hit.pitch_scale = 11.0
        # hit.stream = preload("res://audio/hit1-metal.wav") # Example
    if death:
        death.volume_db = 0
        death.pitch_scale = 1.0
        # death.stream = preload("res://audio/death1.wav") # Example
# Function to play hit sound
func play_hit() -> void:
    if hit and hit.stream != null:
        hit.stop()
        hit.play()
    else:
        print("Hit sound not loaded! Please assign a hit sound file to the 'hit' AudioStreamPlayer node in the AudioController scene.")

# Function to play death sound
func play_death() -> void:
    if death and death.stream != null:
        death.stop()
        death.play()
    else:
        print("Death sound not loaded! Please assign a death sound file to the 'death' AudioStreamPlayer node in the AudioController scene.")

# Function to set hit sound file
func set_hit_sound(audio_stream: AudioStream) -> void:
    if hit:
        hit.stream = audio_stream

# Function to set death sound file
func set_death_sound(audio_stream: AudioStream) -> void:
    if death:
        death.stream = audio_stream

func _process(delta: float) -> void:
    # Handle walk sound timing
    if is_walking:
        walk_timer -= delta
        if walk_timer <= 0.0:
            play_walk()
            walk_timer = walk_interval

# Function to start walking sound loop
func start_walking() -> void:
    if not is_walking:
        is_walking = true
        walk_timer = walk_interval
        play_walk()
        
func play_dash() -> void:
    if dash.stream != null:
        dash.stop()
        dash.play()

# Function to stop walking sound loop
func stop_walking() -> void:
    is_walking = false
    footsteps.stop()

# Function to play walk sound
func play_walk() -> void:
    if footsteps.stream != null:
        footsteps.stop()
        footsteps.play()

# Function to play jump sound
func play_jump() -> void:
    if jump.stream != null:
        jump.stop()
        jump.play()
    else:
        print("Jump sound not loaded! Please assign a jump sound file to the 'jump' AudioStreamPlayer node in the AudioController scene.")

# Function to set walk sound file
func set_walk_sound(audio_stream: AudioStream) -> void:
    footsteps.stream = audio_stream

# Function to set jump sound file
func set_jump_sound(audio_stream: AudioStream) -> void:
    jump.stream = audio_stream

# Function to set dash sound file
func set_dash_sound(audio_stream: AudioStream) -> void:
    dash.stream = audio_stream
