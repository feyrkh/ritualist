extends Node

signal register_mouse_handle(node:Node2D)
signal mouse_entered_editable_component(component)
signal mouse_exited_editable_component(component)
signal mouse_handle_drag_start(global_start_pos:Vector2, dragged_element:RitualDesignElement)
signal mouse_handle_drag_stop(global_end_pos:Vector2, dragged_element:RitualDesignElement)
signal mouse_handle_dragged(global_start_pos:Vector2, global_cur_pos:Vector2, dragged_element:RitualDesignElement)
signal mouse_handle_freeze()
signal mouse_handle_unfreeze()
signal item_menu_open(owningElement:RitualDesignElement)
signal item_menu_close()
signal create_ritual_element(element:RitualDesignElement)

var mouseHandle:Node2D

func _ready():
	register_mouse_handle.connect(_register_mouse_handle)

func _register_mouse_handle(node:Node2D):
	mouseHandle = node
