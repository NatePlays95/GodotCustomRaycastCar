class_name RayCastWheel
extends RayCast

export var apply_forces_at_contact_pos : bool = false

export var is_steer : bool = true
export var is_motor : bool = true

export var wheel_radius : float = 1

export var spring_max_length : float = 1.2
#export var spring_rest_length : float = 1
export var spring_stiffness : float = 15000 # in Newton per Meter (N/m)
export var spring_max_force : float = 5000
export var damping_compress : float = 1000
export var damping_rebound : float = 500

export var turn_radius_degrees : float = 10

onready var rb = get_parent()

#internal variables

var deform : float = 0
var last_deform : float = 0
var extend : float = 0
var last_pos: Vector3 =          Vector3.ZERO
var delta_pos : Vector3 =        Vector3.ZERO  
var contact_pos : Vector3 =      Vector3.ZERO   #in global position
var contact_normal : Vector3 =   Vector3.UP     #in global rotation

var local_up : Vector3 =         Vector3.UP
var local_forward : Vector3 =         Vector3.FORWARD
var local_right : Vector3 =         Vector3.RIGHT

var i_throttle : float = 0
var i_brakes : float = 0
var i_steer : float = 0
var last_steer : float = 0

#debug variables
var debug_spring_force : float = 0
onready var debug_spring_gizmo = DebugLine3D.new()
var debug_throttle_force : float = 0
onready var debug_throttle_gizmo = DebugLine3D.new()
var debug_slip_force : float = 0
onready var debug_slip_gizmo = DebugLine3D.new()


func _ready():
	_initialize_variables()
	
	add_child(debug_spring_gizmo)
	add_child(debug_throttle_gizmo)
	add_child(debug_slip_gizmo)
	pass


func _initialize_variables():
	last_pos = self.global_transform.origin;
	self.cast_to.y = -1 * (spring_max_length + wheel_radius)


func _physics_process(dt):
	_update(dt)
	_process_input(dt)
	_physics_torque(dt)
	_physics_slip(dt)
	_physics_springs(dt)
	#_process_visuals(dt)


func _process(dt):
	_render_wheels(dt)
	_render_debug_gizmos(dt)


func _update(dt):
	local_up = global_transform.basis.y #local up direction
	
	last_deform = deform
	
	var new_pos = self.global_transform.origin
	delta_pos = new_pos - last_pos
	last_pos = new_pos
	
	self.force_raycast_update()
	
	if self.is_colliding():
		contact_pos = self.get_collision_point()
		contact_normal = self.get_collision_normal()
		
		var l = -self.cast_to.y
		#extend is also known as SpringLength
		extend = clamp(contact_pos.distance_to(self.global_transform.origin) - wheel_radius, 0, spring_max_length)
		
		deform = spring_max_length-extend # deformation is X in the elastic energy formula F = KX
		#print(self.name, "  ", l, "  ", extend, "   ", deform)
	else:
		contact_pos = Vector3.ZERO
		contact_normal = Vector3.UP
		extend = -self.cast_to.y - wheel_radius
		deform = 0


#In the future, input should be passed down from the Car node.
func _process_input(dt):
	#STEERING
	if self.is_steer:
		last_steer = i_steer
		i_steer = Input.get_axis("steer_right", "steer_left")
	
	#THROTTLE
	if self.is_motor:
		i_throttle = Input.get_axis("brake", "accelerate")


func _physics_torque(dt):
	#SIMPLISTIC
	debug_throttle_force = 0
	if self.is_colliding() and self.is_motor:
		if (i_throttle != 0):
			var strength = 10000*i_throttle #change to torque passed through the wheels
			var local_forward = global_transform.basis.x
			rb.apply_impulse(get_impulse_pos(), local_forward*strength*dt)
			
			debug_throttle_force = strength


var friction_coeff = 0.8 #sideways
var tire_mass = 25
func _physics_slip(dt):
	#TURN WHEELS
	if self.is_steer:
		var turn_radius_radians = deg2rad(turn_radius_degrees)
		#revert old steer
		self.rotate_y(-last_steer*turn_radius_radians)
		#apply new steer
		self.rotate_y(i_steer*turn_radius_radians)
	
	debug_slip_force = 0
	if self.is_colliding():
		#SIMPLISTIC
		var local_sideways = global_transform.basis.z
		var velocity = delta_pos/dt
		var sideways_velocity = velocity.dot(local_sideways) / global_transform.basis.z.length()
		
		var final_force = -sideways_velocity*friction_coeff*tire_mass/dt
		#rb.(impulse_pos, local_sideways*acceleration*dt)
		rb.apply_impulse(get_impulse_pos(), local_sideways*final_force*dt)
		
		debug_slip_force = final_force


func _physics_springs(dt):
	debug_spring_force = 0
	if self.is_colliding():
		var spring_force = spring_stiffness * deform
		#var dy = delta_pos.dot(local_up)/local_up.length()
		var dy = deform - last_deform
		#print(self.name, "  ", dy, "  ", delta_height)
		
		# if going down, use damp compress
		# if going up, use damp rebound
		var damp_force = -(dy/dt) #speed
		var upordown = sign(dy/dt)
		if upordown == 1: # up
			damp_force *= damping_rebound
		if upordown == -1:
			damp_force *= damping_compress
		
		print(damp_force)
		
		var final_force = spring_force-damp_force
		
		final_force = -damp_force + spring_force/spring_max_length
		final_force = clamp(final_force, -spring_max_force, spring_max_force)
		
		#apply
		rb.apply_impulse(get_impulse_pos(), local_up*final_force*dt)
		
		debug_spring_force = final_force






func get_impulse_pos():
	# impulses are centered onto rb's origin, so we need to account for that
	var impulse_pos = -rb.global_transform.origin
	if apply_forces_at_contact_pos:
		impulse_pos += contact_pos
	else:
		impulse_pos += self.global_transform.origin
	return impulse_pos


func _render_wheels(dt):
	if get_node_or_null("mesh") != null:
		$mesh.transform.origin.y = -extend
		
		var forward_delta_pos = delta_pos.dot(global_transform.basis.x) / global_transform.basis.x.length()
		#perimeter = 2 PI radius, rotation = deltas/r
		var angle = forward_delta_pos / wheel_radius
		$mesh.rotate_z(-angle*0.5)


var gizmo_size_mod = 0.0005
func _render_debug_gizmos(dt):
	debug_spring_gizmo.create_line_pos_pos(Vector3(0,0,0), Vector3.UP*debug_spring_force*gizmo_size_mod, Color.pink)
	debug_throttle_gizmo.create_line_pos_pos(Vector3(0,0,0), Vector3.RIGHT*debug_throttle_force*gizmo_size_mod, Color.yellow)
	debug_slip_gizmo.create_line_pos_pos(Vector3(0,0,0), -Vector3.FORWARD*debug_slip_force*gizmo_size_mod, Color.blue)
	
