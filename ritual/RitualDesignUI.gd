extends Node2D

enum DragMode {MOVE, RESIZE}

var mouseHandle:MouseHandle
var currentInteractiveComponents:Array[RitualDesignElement] = []
var clickableInteractiveComponent:RitualDesignElement = null:
	set(val):
		if val != clickableInteractiveComponent:
			print("Clickable component changed: ", val)
		clickableInteractiveComponent = val
var lastMousePos:Vector2
var drag_mode:DragMode = DragMode.MOVE
@onready var dragModeButtons:Array[Button] = [find_child("MoveButton"), find_child("ResizeButton")]

# Called when the node enters the scene tree for the first time.
func _ready():
	mouseHandle = MouseHandle.new()
	add_child(mouseHandle)
	mouseHandle.visible = false
	RitualDesignEvents.register_mouse_handle.emit(mouseHandle)
	RitualDesignEvents.mouse_entered_editable_component.connect(_add_editable_component)
	RitualDesignEvents.mouse_exited_editable_component.connect(_remove_editable_component)
	RitualDesignEvents.mouse_handle_drag_start.connect(_mouse_handle_drag_start)
	RitualDesignEvents.mouse_handle_drag_stop.connect(_mouse_handle_drag_stop)
	RitualDesignEvents.mouse_handle_dragged.connect(_mouse_handle_dragged)

func _mouse_handle_drag_start(global_start_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		print("Starting drag")
		dragged_element.start_drag()
	else:
		print("Tried to start drag, but no dragged element")
	
func _mouse_handle_drag_stop(global_end_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		print("Stopping drag")
		dragged_element.stop_drag()
	else:
		print("Tried to stop drag, but no dragged element")

func _mouse_handle_dragged(global_start_pos:Vector2, global_end_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		if drag_mode == DragMode.MOVE:
			print("Trying to move")
			dragged_element.drag_move(global_start_pos, global_end_pos)
		elif drag_mode == DragMode.RESIZE:
			print("Trying to resize")
			dragged_element.drag_resize(global_start_pos, global_end_pos)
	else:
		print("Trying to drag with no dragged_element")

func _add_editable_component(component:RitualDesignElement):
	currentInteractiveComponents.append(component)

func _remove_editable_component(component:RitualDesignElement):
	currentInteractiveComponents.erase(component)

func _process(delta):
	_update_mouse_handle_visibility()

func _unhandled_key_input(event:InputEvent):
	if event.is_action_pressed("toggle_drag_mode"):
		_toggle_drag_mode()
		
func _toggle_drag_mode():
	if !mouseHandle.dragging:
		for i in range(dragModeButtons.size()):
			if dragModeButtons[i].button_pressed:
				dragModeButtons[(i+1) % dragModeButtons.size()].button_pressed = true
				break

func _update_mouse_handle_visibility():
	var mouse_world_pos = get_global_mouse_position()
	if mouse_world_pos != lastMousePos:
		lastMousePos = mouse_world_pos
		var best_item:RitualDesignElement = null
		var best_dist = 999999
		for cmp in currentInteractiveComponents:
			var cur_dist = cmp.get_distance_squared(mouse_world_pos)
			if cur_dist < best_dist:
				best_item = cmp
				best_dist = cur_dist
		if best_item != null:
			var actual_dist = best_item.get_distance(mouse_world_pos)
			if actual_dist < RitualDesignElement.MOUSE_RADIUS_BLEED:
				# we're close enough to the mouse handle to render something
				if actual_dist < MouseHandle.HANDLE_RADIUS:
					# we're actually overlapping the mouse handle
					clickableInteractiveComponent = best_item
				mouseHandle.is_clickable(clickableInteractiveComponent)
				mouseHandle.global_position = best_item.get_mouse_handle_point(mouse_world_pos)
				mouseHandle.visible = true
			else:
				# we are close to something that's clickable, but we're too far from the mouse handle
				mouseHandle.visible = false
				clickableInteractiveComponent = null
		else:
			mouseHandle.visible = false
			clickableInteractiveComponent = null

func _on_move_button_toggled(toggled_on):
	if toggled_on:
		drag_mode = DragMode.MOVE

func _on_resize_button_toggled(toggled_on):
	if toggled_on:
		drag_mode = DragMode.RESIZE
