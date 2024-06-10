extends Node2D

var ikbone_class = load("res://ikbone.gd")
var legs = []
# Called when the node enters the scene tree for the first time.
func _init():
	addLeg()
	#pos = Vector2(get_parent().global_position.x,get_parent().global_position.y)
	pass
func _ready():
	#legs = $legs.get_children()
	
	pass # Replace with function body.
func new_ikbone(xy,ang,len,child):
	var ikbone_tmp = ikbone_class.new()
	ikbone_tmp.init(xy,ang,len,child)
	return ikbone_tmp

func addLeg():
	var ikbone_tmp = new_ikbone(Vector2(5,5),0,5,new_ikbone(Vector2(5,10),0,5,null))
	legs.append(ikbone_tmp)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = Vector2(get_parent().global_position.x,get_parent().global_position.y)
	queue_redraw()
	pass
func _draw():
	for leg in legs:
		var direct_state = PhysicsServer2D.space_get_direct_state(PhysicsServer2D.body_get_space(get_parent().get_rid()))
		var ray = PhysicsRayQueryParameters2D.create(global_position,global_position+Vector2(0,5),0xFFFFFFFF,[self.get_parent().get_rid()])
		var result = direct_state.intersect_ray(ray)
		var pos = Vector2(0,5)
		if result != {}:
			pos = result.position
		leg.updateIk(pos)
		while leg != null:
			pos = Vector2(leg.p[0],leg.p[1])
			draw_line(pos,pos+Vector2.RIGHT.rotated(leg.a)*leg.l,Color.BLACK)
			leg = leg.child
