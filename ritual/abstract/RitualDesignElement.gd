extends Node2D
class_name RitualDesignElement
# Naive design element, assumes that the only distance we care about is the center of the square

const INVALID_HANDLE:Vector2 = Vector2(9999999, 9999999)
const DRAG_SNAP:Vector2 = Vector2(25, 25)

var drag_start_pos:Vector2

func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	return global_position

func get_distance_squared(mouse_pos:Vector2) -> float:
	return mouse_pos.distance_squared_to(get_mouse_handle_point(mouse_pos))

func get_distance(mouse_pos:Vector2) -> float:
	return mouse_pos.distance_to(get_mouse_handle_point(mouse_pos))

func start_drag():
	drag_start_pos = global_position

func stop_drag():
	pass

func drag_resize(global_start_pos:Vector2, global_end_pos:Vector2):
	pass

func drag_move(global_start_pos:Vector2, global_end_pos:Vector2):
	global_position = drag_start_pos + (global_end_pos - global_start_pos)
	if Input.is_action_pressed("drag_item_snap"):
		global_position = global_position.snapped(DRAG_SNAP)

func prepare_to_place():
	modulate.a = 0.6
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	
func complete_place():
	modulate.a = 1
	process_mode = ProcessMode.PROCESS_MODE_INHERIT
