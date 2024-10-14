extends BodyAnimator


# Called when the node enters the scene tree for the first time
var target = Vector2(0,0)
func _init():
	pass
func _ready():
	iklimb_add(Vector2(300,0),Vector2(300,40),8)

func updateTarget(t:Vector2):
	target = t
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	iklimb_follow(iklimb_set[0],get_parent().global_position-global_position)
	queue_redraw()
func _draw():
	#draw_polygon(PackedVector2Array([TMPVAR,TMPVAR+Vector2(0,2),TMPVAR+Vector2(2,2),TMPVAR+Vector2(2,0)]),PackedColorArray([Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1)]))
	#draw_polygon(PackedVector2Array([TMPVAR,TMPVAR+Vector2(0,2),TMPVAR+Vector2(2,2),TMPVAR+Vector2(2,0)]),PackedColorArray([Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1)]))
	var pl = get_parent()
	var pl_pos = Vector2(pl.global_position.x,pl.global_position.y)
	for limb in iklimb_set:
		var i = 0
		for seg in limb:
			#draw_line(seg.pos-pl_pos,ikseg_getEnd(seg)-pl_pos,Color.WHITE,2)
			draw_line(seg.pos,ikseg_getEnd(seg),Color.WHITE,2)
			#draw_line(seg.pos,ikseg_getEnd(seg),Color.WHITE,2)
			i+=1
