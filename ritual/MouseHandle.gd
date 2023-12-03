extends Node2D
class_name MouseHandle

const HANDLE_RADIUS:float = 10
const HANDLE_RADIUS_BLEED:float = MouseHandle.HANDLE_RADIUS * 3
const inactive_color = Color(0.9, 0.9, 0.9, 0)
const active_color = Color(0.7, 1, 0.7, 0.95)
const frozen_color = Color(0.7, 0.7, 1, 0.95)

var currentHandleOwner:RitualDesignElement
var mousePosDragStart:Vector2
var frozen:bool = false

func _ready():
	RitualDesignEvents.mouse_handle_freeze.connect(_mouse_handle_freeze)
	RitualDesignEvents.mouse_handle_unfreeze.connect(_mouse_handle_unfreeze)

func _draw():
	draw_circle(Vector2.ZERO, HANDLE_RADIUS, Color(0.9, 0.9, 1, 0.6))

func _mouse_handle_freeze():
	frozen = true
	modulate = frozen_color
	print("Freezing mouse")

func _mouse_handle_unfreeze():
	frozen = false
	modulate = inactive_color
	currentHandleOwner = null
	print("Unfreezing mouse")
	
func is_clickable(designElement:RitualDesignElement, actual_dist:float):
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
	if designElement == null:
		modulate.a = clampf(0.7 - (actual_dist - HANDLE_RADIUS)/HANDLE_RADIUS_BLEED, 0, 0.8)

