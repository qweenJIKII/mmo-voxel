extends Node3D

class_name VoxelDebugDrawer

@export var subsystem_path: NodePath
@export var line_color: Color = Color.DARK_GREEN
@export var line_width: float = 2.0

var _immediate: ImmediateMesh
var _mesh_instance: MeshInstance3D
var _subsystem: AdaptiveVoxelSubsystem

func _ready() -> void:
	_immediate = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.material_override = _create_material()
	add_child(_mesh_instance)
	_mesh_instance.mesh = _immediate
	_resolve_subsystem()

func _process(_delta: float) -> void:
	_draw_debug()

func _draw_debug() -> void:
	if _subsystem == null:
		return
	_immediate.clear_surfaces()
	var nodes := _subsystem.get_debug_nodes()
	if nodes.is_empty():
		return
	_immediate.surface_begin(Mesh.PRIMITIVE_LINES, null)
	_immediate.surface_set_color(line_color)
	for node_aabb in nodes:
		if node_aabb is AABB:
			_draw_aabb(node_aabb)
	_immediate.surface_end()

func _draw_aabb(aabb: AABB) -> void:
	var corners := [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
	]

	var edges := [
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]

	for edge in edges:
		var start: Vector3 = corners[edge[0]]
		var end: Vector3 = corners[edge[1]]
		_immediate.surface_add_vertex(start)
		_immediate.surface_add_vertex(end)

func _create_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = line_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _resolve_subsystem() -> void:
	if subsystem_path.is_empty():
		return
	var node := get_node_or_null(subsystem_path)
	if node == null:
		push_warning("VoxelDebugDrawer: subsystem node not found")
		return
	if not node is AdaptiveVoxelSubsystem:
		push_warning("VoxelDebugDrawer: subsystem node is not AdaptiveVoxelSubsystem")
