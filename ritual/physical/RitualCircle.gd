extends HollowCircleDesignElement

func _ready():
	var mouseRadius = CollisionShape2D.new()
	mouseRadius.shape = CircleShape2D.new()
	mouseRadius.shape.radius = radius + MouseHandle.HANDLE_RADIUS_BLEED
	find_child("DesignElementMouseHandler").add_child(mouseRadius)
	mouseRadius.name = "CollisionShape2D"
	# Have to have a collision shape before calling superclass, it expects collision shape to already exist!
	# We build it dynamically because we don't want to share shapes with a bunch of other circles
	super._ready()

func getSegmentsByRadius(desiredRadius:float) -> int:
	return 40 + roundi(radius/100) * 10

func _draw():
	print("Redrawing ritual circle")
	draw_arc(Vector2.ZERO, radius, 0, 360, getSegmentsByRadius(radius), Color.WHITE, 2, true)
