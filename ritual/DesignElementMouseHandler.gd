extends Area2D

func _on_mouse_entered():
	RitualDesignEvents.mouse_entered_editable_component.emit(owner)

func _on_mouse_exited():
	RitualDesignEvents.mouse_exited_editable_component.emit(owner)
