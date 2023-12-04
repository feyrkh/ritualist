extends Node2D

enum DragMode {MOVE, RESIZE}
enum CursorMode {
	NORMAL, # Moving mouse freely, cursor shows ghosts of what is selectable
	DRAGGING, # In the middle of a drag operation
	PLACING, # In the middle of placing a design element (like a ritual circle)
	CONNECTING, # In the middle of connecting one design element to another
}

var mouseHandle:MouseHandle
var currentInteractiveComponents:Array[RitualDesignElement] = []
var clickableInteractiveComponent:RitualDesignElement = null:
	set(val):
		if val != clickableInteractiveComponent:
			print("Clickable component changed: ", val)
		clickableInteractiveComponent = val
var lastMousePos:Vector2
var dragMode:DragMode = DragMode.MOVE
var cursorMode:CursorMode = CursorMode.NORMAL:
	set(val):
		if val != cursorMode:
			print("Cursor mode changed: ", val)
			cursorMode = val
@onready var dragModeButtons:Array[Button] = [find_child("MoveButton"), find_child("ResizeButton")]
var placingItem:RitualDesignElement

@onready var RitualElements:Node2D = find_child("RitualElements")

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
	RitualDesignEvents.mouse_handle_unfreeze.connect(_mouse_handle_unfreeze)
	RitualDesignEvents.create_ritual_element.connect(_create_ritual_element)

func _create_ritual_element(newElement:RitualDesignElement):
	cursorMode = CursorMode.PLACING
	placingItem = newElement
	get_viewport().warp_mouse(get_viewport_rect().size/2)
	placingItem.prepare_to_place()
	RitualElements.add_child(placingItem)

func _mouse_handle_unfreeze():
	# clear the current clickable component and then check to see which one it should be again
	clickableInteractiveComponent = null
	_update_mouse_handle_visibility()

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
	cursorMode = CursorMode.NORMAL

func _mouse_handle_dragged(global_start_pos:Vector2, global_end_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		if dragMode == DragMode.MOVE:
			print("Trying to move")
			dragged_element.drag_move(global_start_pos, global_end_pos)
		elif dragMode == DragMode.RESIZE:
			print("Trying to resize")
			dragged_element.drag_resize(global_start_pos, global_end_pos)
	else:
		print("Trying to drag with no dragged_element")

func _add_editable_component(component:RitualDesignElement):
	currentInteractiveComponents.append(component)

func _remove_editable_component(component:RitualDesignElement):
	currentInteractiveComponents.erase(component)

func _process(delta):
	match cursorMode:
		CursorMode.PLACING:
			placingItem.global_position = get_global_mouse_position()
			if Input.is_action_pressed("drag_item_snap"):
				placingItem.global_position = placingItem.global_position.snapped(RitualDesignElement.DRAG_SNAP)
		_:
			_update_mouse_handle_visibility()

func _unhandled_key_input(event:InputEvent):
	if event.is_action_pressed("toggle_drag_mode"):
		_toggle_drag_mode()

func _unhandled_input(event:InputEvent):
	if cursorMode == CursorMode.DRAGGING:
		mouseHandle.global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		match cursorMode:
			CursorMode.PLACING:
				_check_placing_input(event)
			CursorMode.CONNECTING:
				_check_connecting_input(event)
			CursorMode.NORMAL, CursorMode.DRAGGING:
				_check_drag_start_or_stop(event)
	elif cursorMode == CursorMode.DRAGGING and event is InputEventMouseMotion:
		RitualDesignEvents.mouse_handle_dragged.emit(mouseHandle.mousePosDragStart, mouseHandle.global_position, mouseHandle.currentHandleOwner)

func _check_placing_input(event:InputEventMouseButton):
	if event.is_action_pressed("place_item"):
		placingItem.complete_place()
		placingItem = null
		cursorMode = CursorMode.NORMAL
	elif event.is_action_pressed("cancel_item"):
		placingItem.queue_free()
		cursorMode = CursorMode.NORMAL

func _check_connecting_input(event:InputEventMouseButton):
	pass

func _check_drag_start_or_stop(event:InputEventMouseButton):
	if event.is_action("drag_item"):
		if mouseHandle.frozen:
			RitualDesignEvents.mouse_handle_unfreeze.emit()
			return
		if event.is_pressed():
			if mouseHandle.currentHandleOwner:
				cursorMode = CursorMode.DRAGGING
				mouseHandle.mousePosDragStart = mouseHandle.global_position
				RitualDesignEvents.mouse_handle_drag_start.emit(mouseHandle.mousePosDragStart, mouseHandle.currentHandleOwner)
		elif event.is_released():
			cursorMode == CursorMode.NORMAL
			RitualDesignEvents.mouse_handle_drag_stop.emit(mouseHandle.global_position, mouseHandle.currentHandleOwner)
		get_viewport().set_input_as_handled()
			

func _toggle_drag_mode():
	if cursorMode != CursorMode.DRAGGING:
		for i in range(dragModeButtons.size()):
			if dragModeButtons[i].button_pressed:
				dragModeButtons[(i+1) % dragModeButtons.size()].button_pressed = true
				break

func _update_mouse_handle_visibility():
	if mouseHandle.frozen or cursorMode == CursorMode.DRAGGING:
		return
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
			if actual_dist < MouseHandle.HANDLE_RADIUS_BLEED:
				# we're close enough to the mouse handle to render something
				if actual_dist < MouseHandle.HANDLE_RADIUS:
					# we're actually overlapping the mouse handle
					clickableInteractiveComponent = best_item
				else:
					clickableInteractiveComponent = null
				mouseHandle.is_clickable(clickableInteractiveComponent, actual_dist)
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
		dragMode = DragMode.MOVE

func _on_resize_button_toggled(toggled_on):
	if toggled_on:
		dragMode = DragMode.RESIZE
