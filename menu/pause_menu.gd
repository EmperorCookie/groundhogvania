extends Node2D


func _on_continue_btn_pressed() -> void:
	self.hide()
	get_tree().paused = false # Replace with function body.


func _on_quit_to_menu_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")


func _on_quit_to_desktop_btn_pressed() -> void:
	get_tree().quit()
