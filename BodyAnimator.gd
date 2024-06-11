extends Node2D

var iklimb_set = []
var TMPVAR = Vector2(0,0)
# Called when the node enters the scene tree for the first time.
func _init():
	#addLeg()
	#pos = Vector2(get_parent().global_position.x,get_parent().global_position.y)
	iklimb_add(Vector2(5,5),Vector2(5,20),2)
	#for limb in iklimb_set:
	#	print(limb.spos + " " + limb.ang + " " + limb.len)

	pass
func printTest():
	var i = 0
	for limb in iklimb_set:
		print("Limb " + str(i))
		for bone in limb:
			print(str(bone.spos)+","+str(bone.ang)+","+str(bone.len))
		i += 1
		print(ikbone_getEndPos(iklimb_getEndBone(limb)))
func _ready():
	#legs = $legs.get_children()
	
	pass # Replace with function body.
func iklimb_add(spos:Vector2,epos:Vector2,joints,vec:Vector2=Vector2(0,1)):
	var limb = []
	var dist = spos.distance_to(epos)
	var i_dist = dist/joints
	var cpos = spos
	var prev = null
	for i in joints:
		var i_spos = cpos
		var i_epos = cpos+(vec*i_dist)
		var i_ang = (i_epos-i_spos).angle()
		#epos=i_epos
		var bone = {spos=i_spos,epos=i_epos,ang=i_ang,len=i_dist,inb=prev,outb=null}
		if prev != null:
			prev.outb = bone
		prev = bone
		cpos = i_epos
		limb.append(bone)
	iklimb_set.append(limb)
func iklimb_getRootBone(limb):
	for bone in limb:
		if bone.inb == null:
			return bone
	return null
func iklimb_getEndBone(limb):
	for bone in limb:
		if bone.outb == null:
			return bone
	return null
func ikbone_getEndPos(bone):
	return bone.spos+(Vector2.from_angle(bone.ang)*bone.len)
func iklimb_endToRoot(limb,target:Vector2):
	var currGoal = target
	var currBone = iklimb_getEndBone(limb)
	while currBone != null:
		#currBone.ang = (Vector2.UP-(currGoal-currBone.spos)).angle()
		currBone.ang = (currGoal-currBone.spos).angle()
		currBone.epos = currGoal
		#currBone.spos = (Vector2.from_angle(currBone.ang)*-currBone.len)+currGoal
		currGoal = currBone.spos
		currBone = currBone.inb
func iklimb_rootToEnd(limb,target:Vector2):
	var currBone = iklimb_getRootBone(limb)
	var currPos = currBone.spos
	while currBone != null:
		currBone.spos = currPos
		#currPos = currBone.spos+(Vector2.from_angle(currBone.ang)*currBone.len)
		currPos = ikbone_getEndPos(currBone)
		currBone = currBone.outb

func iklimb_reach(limb,target:Vector2):
	var i = 0
	var endBone = iklimb_getEndBone(limb)
	#while i<15 && abs(ikbone_getEndPos(endBone)-target) > 0.05:
	#print("Q " + str(ikbone_getEndPos(endBone).distance_to(target)))
	while i<15 && ikbone_getEndPos(endBone).distance_to(target) > 0.05:
		iklimb_endToRoot(limb,target)
		iklimb_rootToEnd(limb,target)
		i+=1
func _process(delta):
	global_position = Vector2(get_parent().global_position.x,get_parent().global_position.y)
	var mousePos = get_global_mouse_position()
	var offset = iklimb_set[0][0].spos
	var reachPos =  Vector2.from_angle(((global_position+offset)-mousePos).angle())*-15
	TMPVAR = reachPos
	#print(reachPos)
	iklimb_reach(iklimb_set[0],reachPos)
	#printTest()
	queue_redraw()
	pass
func _draw():
	draw_polygon(PackedVector2Array([TMPVAR,TMPVAR+Vector2(0,2),TMPVAR+Vector2(2,2),TMPVAR+Vector2(2,0)]),PackedColorArray([Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1),Color(1,0,0,1)]))
	for limb in iklimb_set:
		for bone in limb:
			draw_line(bone.spos,ikbone_getEndPos(bone),Color.WHITE,2)
			#draw_line(bone.spos,bone.epos,Color.WHITE,2)
	#for leg in legs:
	#	var direct_state = PhysicsServer2D.space_get_direct_state(PhysicsServer2D.body_get_space(get_parent().get_rid()))
	#	var ray = PhysicsRayQueryParameters2D.create(global_position,global_position+Vector2(0,5),0xFFFFFFFF,[self.get_parent().get_rid()])
	#	var result = direct_state.intersect_ray(ray)
	#	var pos = Vector2(0,5)
	#	if result != {}:
	#		pos = result.position
	#	leg.updateIk(pos)
	#	while leg != null:
	#		pos = Vector2(leg.p[0],leg.p[1])
	#		draw_line(pos,pos+Vector2.RIGHT.rotated(leg.a)*leg.l,Color.BLACK)
	#		leg = leg.child
"""
func new_ikbone(xy,ang,len,child):
	var ikbone_tmp = ikbone_class.new()
	ikbone_tmp.init(xy,ang,len,child)
	return ikbone_tmp

func addLeg():
	var ikbone_tmp = new_ikbone(Vector2(5,5),0,5,null)
	var final = new_ikbone(Vector2(5,10),0,5,ikbone_tmp)
	legs.append(final)

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
"""
