extends RitualDesignElement
class_name RitualConnection

const COLLISION_POINT_OFFSET = Vector2.RIGHT * 5

@onready var DrawLine:Line2D = $DrawLine
@onready var InputTick:Line2D = $InputTick
@onready var CollisionShape:CollisionShape2D = find_child("CollisionShape2D")

var inputElement:RitualDesignElement
var outputElement:RitualDesignElement
var farEnd:RitualConnectionEndpoint
var inputLocalPosition # nullable Vector2 - if null, picks the point closest to the outputLocalPosition
var outputLocalPosition # nullable Vector2 - if null, picks the point closest to the inputLocalPosition; if both null, picks closest point between the two elements
var direction_vector:Vector2

func _notification(event):
	if event == NOTIFICATION_PREDELETE:
		# Destructor - remove me from any connected elements
		if inputElement and is_instance_valid(inputElement):
			inputElement.remove_connection(self)
		if outputElement and is_instance_valid(outputElement):
			outputElement.remove_connection(self)
		if farEnd and is_instance_valid(farEnd):
			farEnd.queue_free()
		
func allow_drag_mode(dragMode:RitualDesignUI.DragMode):
	match dragMode:
		RitualDesignUI.DragMode.MOVE, RitualDesignUI.DragMode.CONNECTING: return true
		_: return false

func accept_input_connection(conn:RitualConnection):
	return false

func accept_output_connection():
	return false

func set_input_element(element:RitualDesignElement, localPos):
	print("Changing input element: ", element)
	if inputElement:
		inputElement.remove_connection(self)
	inputElement = element
	inputLocalPosition = localPos
	refresh_visual()

func set_output_element(element:RitualDesignElement, localPos):
	print("Changing output element: ", element)
	if outputElement:
		outputElement.remove_connection(self)
	outputElement = element
	outputLocalPosition = localPos
	refresh_visual()

func set_dragged_endpoint(element:RitualDesignElement, localPos):
	set_input_element(element, localPos)

func refresh_visual(snap_to_closest:bool = false):
	if inputElement and outputElement:
		if inputLocalPosition and outputLocalPosition:
			DrawLine.points[0] = inputElement.global_position + inputLocalPosition
			DrawLine.points[1] = outputElement.global_position + outputLocalPosition
		elif inputLocalPosition:
			DrawLine.points[0] = inputElement.global_position + inputLocalPosition
			DrawLine.points[1] = outputElement.get_mouse_handle_point(DrawLine.points[0])
		elif outputLocalPosition:
			DrawLine.points[1] = outputElement.global_position + outputLocalPosition
			DrawLine.points[0] = inputElement.get_mouse_handle_point(DrawLine.points[1])
		else:
			DrawLine.points[1] = outputElement.get_mouse_handle_point(inputElement.global_position)
			DrawLine.points[0] = inputElement.get_mouse_handle_point(DrawLine.points[1])
			# Because the two shapes may not be circular, update the originally chosen point to be closest to whatever actual point was chosen
			DrawLine.points[1] = outputElement.get_mouse_handle_point(DrawLine.points[0])
		_draw_output_tick()
		_draw_input_tick()
	elif inputElement:
		var mouse_pos = get_global_mouse_position()
		if inputLocalPosition:
			DrawLine.points[0] = inputElement.global_position + inputLocalPosition
		else:
			DrawLine.points[0] = inputElement.get_mouse_handle_point(mouse_pos)
		DrawLine.points[1] = mouse_pos
		_draw_input_tick()
		_clear_output_tick()
	elif outputElement:
		var mouse_pos = get_global_mouse_position()
		if outputLocalPosition:
			DrawLine.points[1] = outputElement.global_position + outputLocalPosition
		else:
			DrawLine.points[1] = outputElement.get_mouse_handle_point(mouse_pos)
		DrawLine.points[0] = mouse_pos
		_clear_input_tick()
		_draw_output_tick()
	_update_direction_vector()
	# Update mouse collision shape
	#var lineAngle = DrawLine.points[0].angle_to_point(DrawLine.points[1])
	CollisionShape.global_position = DrawLine.points[0]
	if farEnd:
		farEnd.refresh_visual()
	#mouseDetectShape.points[0] = DrawLine.points[0] - COLLISION_POINT_OFFSET.rotated(lineAngle - PI/4)
	#mouseDetectShape.points[1] = DrawLine.points[0] - COLLISION_POINT_OFFSET.rotated(lineAngle + PI/4) 
	#mouseDetectShape.points[2] = COLLISION_POINT_OFFSET.rotated(lineAngle - PI/4) + DrawLine.points[1]
	#mouseDetectShape.points[3] = COLLISION_POINT_OFFSET.rotated(lineAngle + PI/4) + DrawLine.points[1]

func _clear_input_tick():
	InputTick.visible = false
	
func _clear_output_tick():
	DrawLine.points[2] = DrawLine.points[1] - Vector2.ONE

func _draw_output_tick():
	DrawLine.points[2] = DrawLine.points[1] + Vector2(DrawLine.points[1] - DrawLine.points[0]).normalized().rotated(10) * 20

func _draw_input_tick():
	var dir := Vector2(DrawLine.points[0] - DrawLine.points[1]).normalized() * 10
	var offset := dir.rotated(PI/2)
	InputTick.points[0] = DrawLine.points[0] + offset
	InputTick.points[1] = DrawLine.points[0] - dir
	InputTick.points[2] = DrawLine.points[0] - offset
	InputTick.visible = true

func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	return DrawLine.points[0] + get_direction_vector() * 5

func get_direction_vector():
	return direction_vector

func _update_direction_vector():
	direction_vector = (DrawLine.points[1] - DrawLine.points[0]).normalized()

func start_drag():
	inputElement.remove_connection(self)
	inputElement = null
	dragStartPos = get_global_mouse_position()
	
func stop_drag():
	if !inputElement || !outputElement:
		queue_free()
		return
	inputElement.add_output_connection(self)

func drag_move(global_start_pos:Vector2, global_end_pos:Vector2):
	DrawLine.points[0] = dragStartPos + (global_end_pos - global_start_pos)
	if Input.is_action_pressed("drag_item_snap"):
		global_position = global_position.snapped(DRAG_SNAP)
	RitualDesignEvents.update_ritual_connection.emit(self)
