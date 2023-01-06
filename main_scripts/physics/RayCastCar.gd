class_name RayCastCar
extends RigidBody

export var has_downforce : bool = true
export var downforce_wing_coeff : float = 0.2 #accounts for wing area and lift coeff

var last_pos : Vector3 = Vector3.ZERO
var delta_pos : Vector3 = Vector3.ZERO

func _ready():
	pass


func _physics_process(dt):
	_update(dt)
	if has_downforce:
		_process_downforce(dt)


func _update(dt):
	var new_pos = self.global_transform.origin
	delta_pos = new_pos - last_pos
	last_pos = new_pos
	
	#print("speed: ", round(3.6*delta_pos.length()/dt))


var HALF_P = 0.00119
func _process_downforce(dt):
	var local_down = -global_transform.basis.y
	var local_forward = global_transform.basis.x
	#downforce = 1/2p * A * Cl * V^2
	
	#(v)2 = (ds/dt)2 = ds2 / dt2
	var forward_delta_pos = (delta_pos.dot(local_forward) / local_forward.length()) * local_forward
	var v2 = forward_delta_pos / pow(dt, 2)
	
	var downforce = HALF_P * downforce_wing_coeff * v2
	self.apply_impulse(Vector3.ZERO, local_down*downforce*dt)
	#print(downforce)


func _process(dt):
	if Input.is_action_just_pressed("flip_car"):
		_respawn()

func _respawn():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform.origin.y += 0.5
	global_transform.basis = Basis.IDENTITY
