extends Camera

export var cam_distance : float = 8
export var cam_height : float = 3
export var speed : float = 10

export(NodePath) var car_path
onready var car = get_node_or_null(car_path)

onready var target_pos : Vector3 = car.global_transform.origin

func _ready():
	pass


func _find_position():
	var pos = car.global_transform.origin
	var forward = car.global_transform.basis.x
	var up = Vector3.UP
	
	pos -= forward*cam_distance
	pos += up*cam_height
	
	return pos


func _physics_process(dt):
	
	global_transform.origin = lerp(global_transform.origin, _find_position(), dt*speed)
	look_at(car.global_transform.origin, Vector3.UP)

