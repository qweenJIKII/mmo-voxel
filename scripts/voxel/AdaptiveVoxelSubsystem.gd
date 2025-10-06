extends Node3D

class_name AdaptiveVoxelSubsystem

var voxel_tree: AdaptiveVoxelTree
@export var world_bounds: AABB = AABB(Vector3.ZERO, Vector3.ONE * 1024.0)
@export var chunk_size: Vector3i = Vector3i(32, 32, 32)
@export var max_depth: int = 4
@export var refine_extent: Vector3 = Vector3(32.0, 32.0, 32.0)
@export var retain_extent: Vector3 = Vector3(64.0, 64.0, 64.0)

var _players: Array[Node3D] = []

func _ready() -> void:
	if voxel_tree == null:
		voxel_tree = AdaptiveVoxelTree.new(world_bounds, chunk_size, max_depth)
	_validate_extents()
	_register_players()
	_log_state("Subsystem ready")

func _process(_delta: float) -> void:
	if voxel_tree == null:
		return
	_update_interest_regions()

func _update_interest_regions() -> void:
	if _players.is_empty():
		voxel_tree.prune_outside([])
		return
	var refine_regions: Array[AABB] = []
	var retain_regions: Array[AABB] = []
	for player in _players:
		if not is_instance_valid(player):
			continue
		var refine_region := _make_region(player.global_position, refine_extent)
		var retain_region := _make_region(player.global_position, retain_extent)
		refine_regions.append(refine_region)
		retain_regions.append(retain_region)
	for region in refine_regions:
		voxel_tree.refine_region(region)
	voxel_tree.prune_outside(retain_regions)

func _register_players() -> void:
	_players.clear()
	var tree := get_tree()
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group("players")
	for node in nodes:
		if node is Node3D:
			_players.append(node)

func add_player(player: Node3D) -> void:
	if player == null:
		return
	if not _players.has(player):
		_players.append(player)

func remove_player(player: Node3D) -> void:
	if player == null:
		return
	_players.erase(player)

func set_voxel(voxel_global_position: Vector3, value: float) -> void:
	if voxel_tree == null:
		return
	voxel_tree.set_voxel(voxel_global_position, value)

func clear_voxel(voxel_global_position: Vector3) -> void:
	if voxel_tree == null:
		return
	voxel_tree.clear_voxel(voxel_global_position)

func get_debug_nodes() -> Array:
	if voxel_tree == null:
		return []
	return voxel_tree.query_nodes(world_bounds)

func get_debug_nodes_with_meta() -> Array:
	if voxel_tree == null:
		return []
	return voxel_tree.get_nodes()

func _log_state(message: String) -> void:
	# TODO: 監視ログと統合
	print("[AdaptiveVoxelSubsystem] %s" % message)

func _validate_extents() -> void:
	retain_extent = retain_extent.max(refine_extent)
	refine_extent.x = max(refine_extent.x, float(chunk_size.x))
	refine_extent.y = max(refine_extent.y, float(chunk_size.y))
	refine_extent.z = max(refine_extent.z, float(chunk_size.z))

func _make_region(center: Vector3, half_extents: Vector3) -> AABB:
	var clamped := half_extents
	clamped.x = max(clamped.x, float(chunk_size.x))
	clamped.y = max(clamped.y, float(chunk_size.y))
	clamped.z = max(clamped.z, float(chunk_size.z))
	var region_origin := center - clamped
	var region_size := clamped * 2.0
	return AABB(region_origin, region_size)
