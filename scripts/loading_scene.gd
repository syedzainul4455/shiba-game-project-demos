extends CanvasLayer


signal scene_loaded

@onready var label: Label = $Label
@onready var timer: Timer = $Timer
var sfx_click: AudioStreamPlayer

var dots_count:int = 0
var scene_path: String = ""
var loading_status: int = 0
var scene_ready_to_load: bool = false
var loaded_scene: PackedScene
var artificial_delay_timer: Timer

func _ready() -> void:
    hide()
    set_process(false)
    
    timer.timeout.connect(_on_dots_timer_timeout)
    sfx_click = get_node_or_null("Click") as AudioStreamPlayer
    
    artificial_delay_timer = Timer.new()
    artificial_delay_timer.wait_time = 4.0
    artificial_delay_timer.one_shot = true
    artificial_delay_timer.timeout.connect(_on_artificial_delay_timer_timeout)
    add_child(artificial_delay_timer)
    
func _process(delta: float) -> void:
    loading_status = ResourceLoader.load_threaded_get_status(scene_path)
    match loading_status:
        ResourceLoader.THREAD_LOAD_LOADED:
            _on_scene_loaded()
        ResourceLoader.THREAD_LOAD_FAILED:
            push_error("scene failed to load")
    
func start_loading(path: String) -> void:
    scene_path = path
    show()
    set_process(true)
    timer.start()
    label.text = "loading"
    if sfx_click:
        sfx_click.play()
    
    ResourceLoader.load_threaded_request(scene_path)
    artificial_delay_timer.start()
    
func _on_dots_timer_timeout() -> void:
    dots_count = (dots_count + 1) % 4
    var dots = ""
    match dots_count:
        0:
            dots = ""
        1:
            dots = "."
        2:
            dots = ".."
        3:
            dots = "..."       
        4:
            dots = "...."
    label.text = "loading" + dots
    
    
    
func _on_scene_loaded() -> void:
    loaded_scene = ResourceLoader.load_threaded_get(scene_path)
    scene_ready_to_load = true
    if artificial_delay_timer.time_left > 0:
        return
    _change_scene()
    
func _on_artificial_delay_timer_timeout() -> void:
    if scene_ready_to_load:
        _change_scene()
    
func _change_scene() -> void:
    set_process(false)
    timer.stop()
    artificial_delay_timer.stop()
    
    var tree := get_tree()
    var current_scene = tree.current_scene
    var scene_instance = loaded_scene.instantiate()
    tree.root.add_child(scene_instance)
    tree.set_current_scene(scene_instance)
    
    if current_scene != null and is_instance_valid(current_scene):
        current_scene.queue_free()
    if sfx_click:
        sfx_click.play()
    hide()
    
    scene_path = ""
    scene_ready_to_load = false
    loaded_scene = null
    scene_loaded.emit()
    
    
