extends RitualDesignElement
class_name HollowCircleDesignElement

const RESIZE_SNAP:float = 10
@export var radius:float:
	set(val):
		radius = val
		refresh_radius()

# Finds the closest point to the mouse on the edge of the circle
var collisionShape:CollisionShape2D

func _ready():
	collisionShape = self.find_child("CollisionShape2D", true, false)
	refresh_radius()

func allow_drag_mode(dragMode:RitualDesignUI.DragMode):
	match dragMode:
		RitualDesignUI.DragMode.MOVE, RitualDesignUI.DragMode.CONNECTING, RitualDesignUI.DragMode.RESIZE: return true
		_: return false
		
func refresh_radius():
	if collisionShape != null:
		collisionShape.shape.radius = radius + MouseHandle.HANDLE_RADIUS_BLEED
		queue_redraw()
		refresh_connections()
		print("Queued redraw for my owner: ", owner)
	else:
		print("Tried to update radius, but had no collisionShape")


func refresh_connections():
	# adjust endpoints in case our circle changed size
	for conn in inputConnections:
		# we are the output of our input connections, so update their endpoint if they have one
		if conn.outputLocalPosition:
			conn.outputLocalPosition = conn.outputLocalPosition.normalized() * radius
	for conn in outputConnections:
		if conn.inputLocalPosition:
			conn.inputLocalPosition = conn.inputLocalPosition.normalized() * radius
	# redraw connections
	super.refresh_connections()


func get_mouse_handle_point(mouse_pos:Vector2) -> Vector2:
	var normalized = (mouse_pos - global_position).normalized()
	if normalized.length_squared() == 0:
		return RitualDesignElement.INVALID_HANDLE
	var edge = normalized * radius
	var world_pos = edge + global_position
	return world_pos 

func drag_resize(global_start_pos:Vector2, global_end_pos:Vector2):
	#print("Trying to change radius: ", global_start_pos, global_end_pos, global_position)
	radius = clamp((global_end_pos - global_position).length(), 50, 400)
	if Input.is_action_pressed("drag_item_snap"):
		radius = snapped(radius, RESIZE_SNAP)
	print("New radius: ", radius)

