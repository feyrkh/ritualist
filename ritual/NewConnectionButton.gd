extends Button


func _ready():
	pressed.connect(_create_new_connection)

func _create_new_connection():
	var new_element:RitualDesignElement = preload("res://ritual/physical/RitualConnection.tscn").instantiate()
	RitualDesignEvents.start_connection.emit(new_element)

