extends Button


func _ready():
	pressed.connect(_create_new_circle)

func _create_new_circle():
	var new_element:RitualDesignElement = preload("res://ritual/physical/RitualCircle.tscn").instantiate()
	RitualDesignEvents.create_ritual_element.emit(new_element)

