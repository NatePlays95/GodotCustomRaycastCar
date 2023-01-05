class_name RayCastWheel
extends RayCast



export var is_steer : bool = true
export var is_motor : bool = true

export var spring_max_length : float = 1.2
#export var spring_rest_length : float = 1
export var spring_stiffness : float = 15000 # in Newton per Meter (N/m)
export var damping_compress : float = 1000
export var damping_rebound : float = 500
export var turn_radius_degrees : float = 20

onready var rb = get_parent()

#internal variables
var deform : float = 0
var extend : float = 0
var last_pos: Vector3 =          Vector3.ZERO
var delta_pos : Vector3 =        Vector3.ZERO   #in global rotation
var contact_pos : Vector3 =      Vector3.ZERO   #in global position
var contact_normal : Vector3 =   Vector3.UP     #in global rotation
var local_up : Vector3 =         Vector3.UP

var i_throttle : float = 0
var i_brakes : float = 0
var i_steer : float = 0
var old_steer : float = 0

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
	self.cast_to.y = -spring_max_length


func _physics_process(dt):
	_update(dt)
	_process_input(dt)
	_process_torque(dt)
	_process_slip(dt)
	_process_springs(dt)
	#_process_visuals(dt)


func _process(dt):
	_render_debug_gizmos(dt)


func _update(dt):
	self.force_raycast_update()
	
	var new_pos = self.global_transform.origin
	delta_pos = new_pos - last_pos
	last_pos = new_pos
	
	if self.is_colliding():
		contact_pos = self.get_collision_point()
		contact_normal = self.get_collision_normal()
		
		var l = -self.cast_to.y
		var extend = contact_pos.distance_to(self.global_transform.origin)
		deform = l-extend # deformation is X in the elastic energy formula F = KX
	else:
		contact_pos = Vector3.ZERO
		contact_normal = Vector3.UP
		deform = 0


#In the future, input should be passed down from the Car node.
func _process_input(dt):
	#STEERING
	if self.is_steer:
		old_steer = i_steer
		i_steer = Input.get_axis("steer_right", "steer_left")
	
	#THROTTLE
	if self.is_motor:
		i_throttle = Input.get_axis("brake", "accelerate")


func _process_torque(dt):
	#SIMPLISTIC
	debug_throttle_force = 0
	if self.is_colliding() and self.is_motor:
		if (i_throttle != 0):
			var strength = 10000*i_throttle #change to torque passed through the wheels
			var local_forward = global_transform.basis.x
			var impulse_pos = self.global_transform.origin - rb.global_transform.origin
			rb.apply_impulse(impulse_pos, local_forward*strength*dt)
			
			debug_throttle_force = strength


var traction_coeff = 1
var tire_mass = 25
func _process_slip(dt):
	#TURN WHEELS
	if self.is_steer:
		var turn_radius_radians = deg2rad(turn_radius_degrees)
		#revert old steer
		self.rotate_y(-old_steer*turn_radius_radians)
		#apply new steer
		self.rotate_y(i_steer*turn_radius_radians)
	
	debug_slip_force = 0
	if self.is_colliding():
		#SIMPLISTIC
		var local_sideways = global_transform.basis.z
		var velocity = delta_pos/dt
		var sideways_velocity = velocity.dot(local_sideways) / global_transform.basis.z.length()
		
		var final_force = -sideways_velocity*traction_coeff*tire_mass/dt
		var impulse_pos = self.global_transform.origin - rb.global_transform.origin
		#rb.apply_impulse(impulse_pos, local_sideways*acceleration*dt)
		rb.apply_impulse(impulse_pos, local_sideways*final_force*dt)
		
		debug_slip_force = final_force


func _process_springs(dt):
	debug_spring_force = 0
	if self.is_colliding():
		var spring_force = spring_stiffness * deform
		local_up = global_transform.basis.y #local up direction
		var dy = delta_pos.dot(local_up)/local_up.length()
		
		# if going down, use damp compress
		# if going up, use damp rebound
		var damp_force = (dy/dt)
		var upordown = sign(dy/dt)
		if upordown == 1: # up
			damp_force *= damping_rebound
		if upordown == -1:
			damp_force *= damping_compress
		
		var final_force = spring_force-damp_force
		
		final_force = -damp_force + spring_force/spring_max_length
		# impulses are centered onto rb's origin, so we need to account for that
		var impulse_pos = self.global_transform.origin - rb.global_transform.origin
		#apply
		rb.apply_impulse(impulse_pos, local_up*final_force*dt)
		
		debug_spring_force = final_force







var gizmo_size_mod = 0.0005
func _render_debug_gizmos(dt):
	debug_spring_gizmo.create_line_pos_pos(Vector3(0,0,0), Vector3.UP*debug_spring_force*gizmo_size_mod, Color.red)
	debug_throttle_gizmo.create_line_pos_pos(Vector3(0,0,0), Vector3.RIGHT*debug_throttle_force*gizmo_size_mod, Color.green)
	debug_slip_gizmo.create_line_pos_pos(Vector3(0,0,0), -Vector3.FORWARD*debug_slip_force*gizmo_size_mod, Color.blue)
	print(debug_throttle_force)
	
