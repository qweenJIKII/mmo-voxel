extends Node3D

class_name VoxelMeshStreamer

@export var subsystem_path: NodePath
@export var mesh_color: Color = Color(0.2, 0.8, 1.0, 0.3)

var _subsystem: AdaptiveVoxelSubsystem
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _last_signature := 0

func _ready() -> void:
	_resolve_subsystem()
	_setup_multimesh()

func _process(_delta: float) -> void:
	if _subsystem == null:
		return
	_refresh_multimesh()

func _resolve_subsystem() -> void:
	if subsystem_path.is_empty():
		push_warning("VoxelMeshStreamer: subsystem_path is empty")
		return
	var node := get_node_or_null(subsystem_path)
	if node == null:
		push_warning("VoxelMeshStreamer: subsystem node not found")
		return
	if node is AdaptiveVoxelSubsystem:
		_subsystem = node
	else:
		push_warning("VoxelMeshStreamer: subsystem node is not AdaptiveVoxelSubsystem")

func _setup_multimesh() -> void:
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = _create_material()
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3.ONE
	_multimesh.mesh = cube_mesh

func _refresh_multimesh() -> void:
	var entries: Array = []
	if _subsystem.has_method("get_debug_nodes_with_meta"):
		entries = _subsystem.get_debug_nodes_with_meta()
	else:
		var raw_nodes := _subsystem.get_debug_nodes()
		for aabb in raw_nodes:
			entries.append({"aabb": aabb, "depth": 0})
	var signature := entries.size()
	if signature != _last_signature:
		_last_signature = signature
	_multimesh.instance_count = entries.size()
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var aabb: AABB = entry.get("aabb", AABB())
		var center := aabb.position + aabb.size * 0.5
		var instance_basis := Basis.IDENTITY.scaled(aabb.size)
		var instance_transform := Transform3D.IDENTITY
		instance_transform.origin = center
		instance_transform.basis = instance_basis
		_multimesh.set_instance_transform(i, instance_transform)

func _create_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = mesh_color
	return mat
