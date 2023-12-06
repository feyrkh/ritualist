extends RitualDesignElement
class_name RitualConnectionEndpoint

var connectionOwner:RitualConnection

func setup(conn:RitualConnection):
	connectionOwner = conn
	conn.farEnd = self
	refresh_visual()

func _notification(event):
	if event == NOTIFICATION_PREDELETE:
		# Destructor - remove me from any connected elements
		if connectionOwner and is_instance_valid(connectionOwner):
			connectionOwner.queue_free()

func refresh_visual():
	global_position = connectionOwner.DrawLine.points[1]

func allow_drag_mode(dragMode:RitualDesignUI.DragMode):
	match dragMode:
		RitualDesignUI.DragMode.MOVE, RitualDesignUI.DragMode.CONNECTING: return true
		_: return false

func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	return connectionOwner.DrawLine.points[1] - connectionOwner.get_direction_vector() * 5

func set_dragged_endpoint(element:RitualDesignElement, localPos):
	connectionOwner.set_output_element(element, localPos)
	
func drag_move(global_start_pos:Vector2, global_end_pos:Vector2):
	if Input.is_action_pressed("drag_item_snap"):
		global_position = global_position.snapped(DRAG_SNAP)
	RitualDesignEvents.update_ritual_connection_endpoint.emit(self)

func stop_drag():
	if !connectionOwner.inputElement || !connectionOwner.outputElement:
		connectionOwner.queue_free()
		queue_free()
		return
	connectionOwner.outputElement.add_input_connection(connectionOwner)
	global_position = connectionOwner.DrawLine.points[1]

func accept_input_connection(conn:RitualConnection):
	return false

func accept_output_connection():
	return false
