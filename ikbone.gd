extends Node2D

var l
var parent
var child
var p = Vector2(0,0)
var a = 0
# Called when the node enters the scene tree for the first time.


func init(pIn,ang,len,c):
	child = c
	l = len
	p = pIn
	a = ang

func updateIk(target):
	var localTarget = rotate_point(translate_point(target,-p[0],-p[1]),-a)
	var endPoint;
	if child != null:
		endPoint = child.updateIk(localTarget)
	else:
		endPoint = [l,0]
	var shiftAng = angle(localTarget)-angle(endPoint)
	a += shiftAng
	return translate_point(rotate_point(endPoint,a),p[0],p[1])
func _ready():
	pass # Replace with function body.
func rotate_point(p,a):
	return [p[0]*cos(a)-p[1]*sin(a),p[0]*sin(a)+p[1]*cos(a)]
func translate_point(p,x,y):
	return [p[0]+x,p[1]+y]
func angle(p):
	return atan2(p[0],p[1])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
