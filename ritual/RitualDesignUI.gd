extends Node2D
class_name RitualDesignUI

enum DragMode {MOVE, RESIZE, CONNECTING}
enum CursorMode {
	NORMAL, # Moving mouse freely, cursor shows ghosts of what is selectable
	DRAGGING, # In the middle of a drag operation
	PLACING, # In the middle of placing a design element (like a ritual circle)
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
@onready var dragModeButtons:Array[Button] = [find_child("MoveButton"), find_child("ResizeButton"), find_child("ConnectButton")]
var placingItem:RitualDesignElement
var placingConnection:RitualConnection
var connectionStartElement:RitualDesignElement
var connectionFinishElement:RitualDesignElement

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
	RitualDesignEvents.update_ritual_connection.connect(_update_ritual_connection)

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
		if dragMode == DragMode.CONNECTING:
			print("Starting connection")
			connectionStartElement = dragged_element
			placingConnection = preload("res://ritual/physical/RitualConnection.tscn").instantiate()
			RitualElements.add_child(placingConnection)
			var inputTargetPos = null
			if Input.is_action_pressed("drag_item_snap"):
				inputTargetPos = connectionStartElement.get_mouse_handle_point(get_global_mouse_position()) - connectionStartElement.global_position
			print("Starting connection drag, input local pos: ", inputTargetPos)
			placingConnection.set_input_element(connectionStartElement, inputTargetPos)
		else:
			print("Starting drag")
			dragged_element.start_drag()
	else:
		print("Tried to start drag, but no dragged element")
		cursorMode = CursorMode.NORMAL
	
func _mouse_handle_drag_stop(global_end_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		print("Stopping drag")
		if dragMode == DragMode.CONNECTING:
			if placingConnection.outputElement == null || placingConnection.inputElement == null:
				print("Deleting connection, it doesn't have two endpoints")
				placingConnection.queue_free()
			else:
				print("Completing connection")
				placingConnection.inputElement.add_output_connection(placingConnection)
				placingConnection.outputElement.add_input_connection(placingConnection)
		else:
			dragged_element.stop_drag()
		cursorMode = CursorMode.NORMAL
	else:
		print("Tried to stop drag, but no dragged element")
	cursorMode = CursorMode.NORMAL

func _mouse_handle_dragged(global_start_pos:Vector2, global_end_pos:Vector2, dragged_element:RitualDesignElement):
	if dragged_element:
		if dragMode == DragMode.MOVE:
			dragged_element.drag_move(global_start_pos, global_end_pos)
		elif dragMode == DragMode.RESIZE:
			dragged_element.drag_resize(global_start_pos, global_end_pos)
		elif dragMode == DragMode.CONNECTING:
			_update_connection_visual()
	else:
		pass
		#print("Trying to drag with no dragged_element")

func _update_ritual_connection(conn:RitualConnection):
	placingConnection = conn
	_update_connection_visual()

func _update_connection_visual():
	var mouse_pos = get_global_mouse_position()
	var closest_item = _find_closest_mouse_handle_point_to_pos(mouse_pos)
	if closest_item and closest_item != connectionStartElement:
		var actual_dist = closest_item.get_distance(mouse_pos)
		# we're close enough to the mouse handle to render something
		if actual_dist < MouseHandle.HANDLE_RADIUS:
			var localPos = null
			if Input.is_action_pressed("drag_item_snap"):
				localPos = closest_item.get_mouse_handle_point(get_global_mouse_position()) - closest_item.global_position
			placingConnection.set_output_element(closest_item, localPos)
		else:
			placingConnection.set_output_element(null, null)
	else:
		placingConnection.refresh_visual()

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

func _find_closest_mouse_handle_point_to_pos(world_pos:Vector2):
	var best_item:RitualDesignElement = null
	var best_dist = 999999
	var need_cleanup := false
	for cmp in currentInteractiveComponents:
		if !is_instance_valid(cmp):
			need_cleanup = true
			continue
		if cursorMode == CursorMode.DRAGGING && dragMode == DragMode.CONNECTING:
			if placingConnection:
				if (placingConnection.dragging_output_end() and !cmp.accept_input_connection(placingConnection)) or (!placingConnection.dragging_output_end() and !cmp.accept_output_connection()):
					# if we are currently looking for an output point for the connection we're
					# dragging, then skip any elements that won't accept this connection as input, or vice versa
					continue
		if !cmp.allow_drag_mode(dragMode):
			continue
		var cur_dist = cmp.get_distance_squared(world_pos)
		if cur_dist < best_dist:
			best_item = cmp
			best_dist = cur_dist
	if need_cleanup:
		currentInteractiveComponents = currentInteractiveComponents.filter(func(el): return el != null)
	return best_item

func _update_mouse_handle_visibility():
	if mouseHandle.frozen or cursorMode == CursorMode.DRAGGING:
		return
	var mouse_world_pos = get_global_mouse_position()
	if mouse_world_pos != lastMousePos:
		lastMousePos = mouse_world_pos
		var best_item = _find_closest_mouse_handle_point_to_pos(mouse_world_pos)
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

func _on_connect_button_toggled(toggled_on):
	if toggled_on:
		dragMode = DragMode.CONNECTING
