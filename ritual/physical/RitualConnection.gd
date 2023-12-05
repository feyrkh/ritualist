extends Node2D
class_name RitualConnection

@onready var DrawLine:Line2D = $DrawLine
var inputElement:RitualDesignElement
var outputElement:RitualDesignElement
var inputLocalPosition # nullable Vector2 - if null, picks the point closest to the outputLocalPosition
var outputLocalPosition # nullable Vector2 - if null, picks the point closest to the inputLocalPosition; if both null, picks closest point between the two elements

func set_input_element(element:RitualDesignElement, localPos):
	inputElement = element
	inputLocalPosition = localPos
	refresh_visual()

func set_output_element(element:RitualDesignElement, localPos):
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

