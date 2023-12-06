extends Node2D
class_name RitualDesignElement
# Naive design element, assumes that the only distance we care about is the center of the square

const INVALID_HANDLE:Vector2 = Vector2(9999999, 9999999)
const DRAG_SNAP:Vector2 = Vector2(25, 25)

var dragStartPos:Vector2
var inputConnections:Array[RitualConnection]
var outputConnections:Array[RitualConnection]

func _notification(event):
	if event == NOTIFICATION_PREDELETE:
		# Destructor - delete any connections to/from this node
		for conn in inputConnections:
			conn.queue_free()
		for conn in outputConnections:
			conn.queue_free()

func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	return global_position

func get_distance_squared(mouse_pos:Vector2) -> float:
	return mouse_pos.distance_squared_to(get_mouse_handle_point(mouse_pos))

func get_distance(mouse_pos:Vector2) -> float:
	return mouse_pos.distance_to(get_mouse_handle_point(mouse_pos))

func allow_drag_mode(dragMode:RitualDesignUI.DragMode):
	match dragMode:
		RitualDesignUI.DragMode.MOVE: return true
		_: return false

func start_drag():
	dragStartPos = global_position

func stop_drag():
	pass

func drag_resize(global_start_pos:Vector2, global_end_pos:Vector2):
	pass

func drag_move(global_start_pos:Vector2, global_end_pos:Vector2):
	global_position = dragStartPos + (global_end_pos - global_start_pos)
	if Input.is_action_pressed("drag_item_snap"):
		global_position = global_position.snapped(DRAG_SNAP)
	refresh_connections()

func prepare_to_place():
	modulate.a = 0.6
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	
func complete_place():
	modulate.a = 1
	process_mode = ProcessMode.PROCESS_MODE_INHERIT

func add_input_connection(conn:RitualConnection):
	inputConnections.append(conn)

func add_output_connection(conn:RitualConnection):
	outputConnections.append(conn)

func remove_connection(conn:RitualConnection):
	inputConnections.erase(conn)
	outputConnections.erase(conn)

func refresh_connections():
	for conn in inputConnections:
		conn.refresh_visual()
	for conn in outputConnections:
		conn.refresh_visual()

func accept_input_connection(conn:RitualConnection):
	if conn.inputElement == self:
		# no connection from myself to myself 
		return false
	return true

func accept_output_connection():
	return false
