extends Node2D
class_name MouseHandle

const HANDLE_RADIUS = 10
const inactive_color = Color(0.9, 0.9, 0.9, 0.3)
const active_color = Color(0.9, 0.9, 1.0, 0.9)

var currentHandleOwner:RitualDesignElement
var dragging:bool = false
var mousePosDragStart:Vector2

func _draw():
	draw_circle(Vector2.ZERO, HANDLE_RADIUS, Color(0.9, 0.9, 1, 0.6))

func is_clickable(designElement:RitualDesignElement):
	if dragging:
		print("Dragging, skipping is_clickable")
		return
	if designElement == null and currentHandleOwner != null:
		modulate = inactive_color
		currentHandleOwner = null
		set_process_unhandled_input(false)
		print("Selected ", currentHandleOwner, " as current handle owner")
	elif designElement != null and designElement != currentHandleOwner:
		modulate = active_color
		currentHandleOwner = designElement
		set_process_unhandled_input(true)
		print("Selected ", currentHandleOwner, " as current handle owner")

func _unhandled_input(event:InputEvent):
	if dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton and event.is_action("drag_item"):
		if event.is_pressed():
			if currentHandleOwner:
				dragging = true
				mousePosDragStart = get_global_mouse_position()
				RitualDesignEvents.mouse_handle_drag_start.emit(mousePosDragStart, currentHandleOwner)
		elif event.is_released():
			dragging = false
			RitualDesignEvents.mouse_handle_drag_stop.emit(global_position, currentHandleOwner)
		get_viewport().set_input_as_handled()
	elif dragging and event is InputEventMouseMotion:
		RitualDesignEvents.mouse_handle_dragged.emit(mousePosDragStart, global_position, currentHandleOwner)
			
