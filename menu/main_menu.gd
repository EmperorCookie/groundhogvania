extends Node2D


func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/test_level/test_level.tscn")# Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
