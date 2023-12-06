extends RitualDesignElement
class_name RitualConnection

const COLLISION_POINT_OFFSET = Vector2.RIGHT * MouseHandle.HANDLE_RADIUS_BLEED

@onready var DrawLine:Line2D = $DrawLine
@onready var CollisionShape:CollisionShape2D = find_child("CollisionShape2D")
var mouseDetectShape:ConvexPolygonShape2D

var inputElement:RitualDesignElement
var outputElement:RitualDesignElement
var inputLocalPosition # nullable Vector2 - if null, picks the point closest to the outputLocalPosition
var outputLocalPosition # nullable Vector2 - if null, picks the point closest to the inputLocalPosition; if both null, picks closest point between the two elements
var _moving_point:int = 1

func _ready():
	mouseDetectShape = ConvexPolygonShape2D.new()
	mouseDetectShape.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	CollisionShape.shape = mouseDetectShape

func _notification(event):
	if event == NOTIFICATION_PREDELETE:
		# Destructor - remove me from any connected elements
		if inputElement:
			inputElement.remove_connection(self)
		if outputElement:
			outputElement.remove_connection(self)
		
func allow_drag_mode(dragMode:RitualDesignUI.DragMode):
	match dragMode:
		RitualDesignUI.DragMode.MOVE: return true
		_: return false

func dragging_output_end():
	return _moving_point == 1

func accept_input_connection(conn:RitualConnection):
	return false

func accept_output_connection():
	return false

func set_input_element(element:RitualDesignElement, localPos):
	print("Changing input element: ", element)
	inputElement = element
	inputLocalPosition = localPos
	refresh_visual()

func set_output_element(element:RitualDesignElement, localPos):
	print("Changing output element: ", element)
	outputElement = element
	outputLocalPosition = localPos
	refresh_visual()

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
			# Find the mouse handle point on the input element based on the center of the output element
			DrawLine.points[0] = inputElement.get_mouse_handle_point(outputElement.global_position)
			# Find the mouse handle point on the output element based on the previously identified handle on the input point
			DrawLine.points[1] = outputElement.get_mouse_handle_point(DrawLine.points[0])
			# Because the two shapes may not be circular, update the originally chosen point to be closest to whatever actual point was chosen
			DrawLine.points[0] = inputElement.get_mouse_handle_point(DrawLine.points[1])
		DrawLine.points[2] = DrawLine.points[1] + Vector2(DrawLine.points[1] - DrawLine.points[0]).normalized().rotated(10) * 20
	elif inputElement:
		var mouse_pos = get_global_mouse_position()
		if inputLocalPosition:
			DrawLine.points[0] = inputElement.global_position + inputLocalPosition
		else:
			DrawLine.points[0] = inputElement.get_mouse_handle_point(mouse_pos)
		DrawLine.points[1] = mouse_pos
		DrawLine.points[2] = DrawLine.points[1] - Vector2.ONE
	var lineAngle = DrawLine.points[0].angle_to_point(DrawLine.points[1])
	mouseDetectShape.points[0] = DrawLine.points[0] - COLLISION_POINT_OFFSET.rotated(lineAngle - PI/4)
	mouseDetectShape.points[1] = DrawLine.points[0] - COLLISION_POINT_OFFSET.rotated(lineAngle + PI/4) 
	mouseDetectShape.points[2] = COLLISION_POINT_OFFSET.rotated(lineAngle - PI/4) + DrawLine.points[1]
	mouseDetectShape.points[3] = COLLISION_POINT_OFFSET.rotated(lineAngle + PI/4) + DrawLine.points[1]

func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	var dist_from_start = (mouse_pos - DrawLine.points[0]).length_squared()
	var dist_from_end = (mouse_pos - DrawLine.points[1]).length_squared()
	var unit = (DrawLine.points[1] - DrawLine.points[0]).normalized() * 3
	if dist_from_start < dist_from_end:
		return DrawLine.points[0] + unit
	else:
		return DrawLine.points[1] - unit

func start_drag():
	var mouse_pos = get_global_mouse_position()
	var dist_from_start = (mouse_pos - DrawLine.points[0]).length_squared()
	var dist_from_end = (mouse_pos - DrawLine.points[1]).length_squared()
	if dist_from_start < dist_from_end:
		_moving_point = 0
		inputElement.remove_connection(self)
		inputElement = null
	else:
		_moving_point = 1
		outputElement.remove_connection(self)
		outputElement = null

func stop_drag():
	if !inputElement || !outputElement:
		queue_free()
		return
	if _moving_point == 0:
		inputElement.add_output_connection(self)
	else:
		outputElement.add_input_connection(self)
	_moving_point = -1

func drag_move(global_start_pos:Vector2, global_end_pos:Vector2):
	if _moving_point > 0:
		DrawLine.points[_moving_point] = dragStartPos + (global_end_pos - global_start_pos)
		if Input.is_action_pressed("drag_item_snap"):
			global_position = global_position.snapped(DRAG_SNAP)
	RitualDesignEvents.update_ritual_connection.emit(self)
