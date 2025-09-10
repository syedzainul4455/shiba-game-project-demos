extends Node

# Audio controller singleton for managing game sounds
# This script is attached to the AudioController scene which is loaded as AutoLoad

# Reference to existing AudioStreamPlayer nodes in the scene
@onready var footsteps: AudioStreamPlayer = $footsteps
@onready var jump: AudioStreamPlayer = $jump

# Walk sound timing variables
var walk_timer: float = 0.0
var walk_interval: float = 0.3  # Time between walk sound plays
var is_walking: bool = false

func _ready() -> void:
    # Set up walk sound properties
    footsteps.volume_db = -10.0  # Adjust volume as needed
    footsteps.pitch_scale = 1.0
    
    # Set up jump sound properties
    jump.volume_db = -15.0   # Lower volume for jump sounds
    jump.pitch_scale = 1.0
    
    # Load audio files (you'll need to add these audio files to your project)
    # footsteps.stream = preload("res://audio/walk.wav")
    # jump.stream = preload("res://audio/jump.wav")

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
