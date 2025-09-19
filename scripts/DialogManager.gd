extends Node2D

@onready var text_box_scene = preload("res://UI/text box/text_box.tscn")

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var sfx: AudioStream

var is_dialog_active = false 
var can_advance_line = false 
var double_press_timer = 0.0
var last_press_time = 0.0
var double_press_threshold = 0.3

signal dialog_finished()

func start_dialog(position: Vector2, lines: Array[String], speech_sfx: AudioStream):
    if is_dialog_active:
        return
        
    dialog_lines = lines
    text_box_position = position
    sfx = speech_sfx
    _show_text_box()
    
    is_dialog_active = true
    
func _show_text_box():
    text_box = text_box_scene.instantiate()
    text_box.finished_displaying.connect(_on_text_box_finished_displaying)
    get_tree().root.add_child(text_box)
    text_box.global_position = text_box_position
    text_box.display_text(dialog_lines[current_line_index], sfx)
    can_advance_line = false
    
func _on_text_box_finished_displaying():
    can_advance_line = true 
    
func _process(delta: float):
    if is_dialog_active:
        double_press_timer += delta

func _unhandled_input(event):
    if event.is_action_pressed("advance_dialog") && is_dialog_active:
        var current_time = Time.get_time_dict_from_system()
        var current_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
        var time_since_last_press = current_seconds - last_press_time
        
        # Check for double press (within threshold)
        if time_since_last_press < double_press_threshold:
            # Double press - skip animation and show full text
            if text_box and text_box.has_method("show_full_text"):
                text_box.show_full_text()
            can_advance_line = true
        else:
            # Single press - normal behavior
            if can_advance_line:
                text_box.queue_free()
                
                current_line_index += 1
                if current_line_index >= dialog_lines.size():
                    is_dialog_active = false
                    current_line_index = 0 
                    dialog_finished.emit()
                    return
                    
                _show_text_box()
        
        last_press_time = current_seconds
    
