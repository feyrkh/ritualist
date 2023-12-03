class_name ZoomingCamera
extends Camera2D

# Lower cap for the `_zoom_level`.
@export var min_zoom := 0.5
# Upper cap for the `_zoom_level`.
@export var max_zoom := 2.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
@export var zoom_factor := 0.1
# Duration of the zoom's tween animation.
@export var zoom_duration := 0.2
@onready var zoom_tween: Tween

var mouse_start_pos:Vector2
var screen_start_pos:Vector2
var dragging:bool = false

# The camera's target zoom level.
var _zoom_level := 1.0:
	set(value):
		# We limit the value between `min_zoom` and `max_zoom`
		_zoom_level = clamp(value, min_zoom, max_zoom)
		# Then, we ask the tween node to animate the camera's `zoom` property from its current value
		# to the target zoom level.
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = self.create_tween()
		zoom_tween.tween_property(
			self,
			"zoom",
			Vector2(_zoom_level, _zoom_level),
			zoom_duration
		)

		
func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		# Inside a given class, we need to either write `self._zoom_level = ...` or explicitly
		# call the setter function to use it.
		_zoom_level = (_zoom_level - zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_zoom_level = (_zoom_level + zoom_factor)
	if event.is_action("drag_camera"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_pos = position
			dragging = true
		else:
			dragging = false
	elif dragging and event is InputEventMouseMotion:
		position = ((mouse_start_pos - event.position) / _zoom_level)  + screen_start_pos
