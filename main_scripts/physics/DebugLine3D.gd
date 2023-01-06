class_name DebugLine3D
extends ImmediateGeometry

var pos : Vector3
var dir : Vector3
var size : float
var col : Color

func _ready():
	var material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.vertex_color_use_as_albedo = true
	self.material_override = material
	
	pass

func create_line_pos_dir(position, direction, length:float, color:Color):
	self.clear()
	self.begin(PrimitiveMesh.PRIMITIVE_LINE_STRIP)
	self.set_color(color)
	self.add_vertex(position) 
	self.add_vertex(position + direction*length)
	self.end()

func create_line_pos_pos(pos1, pos2, color:Color):
	self.clear()
	self.begin(PrimitiveMesh.PRIMITIVE_LINE_STRIP)
	self.set_color(color)
	self.add_vertex(pos1) 
	self.add_vertex(pos2)
	self.end()

