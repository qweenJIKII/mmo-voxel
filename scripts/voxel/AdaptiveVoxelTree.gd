extends RefCounted

class_name AdaptiveVoxelTree

# TODO: Godot 4.x での GDExtension 実装を置き換える。

var root_aabb: AABB
var chunk_size := Vector3i(32, 32, 32)
var max_depth := 4

var _nodes: Dictionary = {}
var _voxel_values: Dictionary = {}

func _init(aabb := AABB(Vector3.ZERO, Vector3.ONE * 1024.0), chunk_size_in := Vector3i(32, 32, 32), max_depth_in := 4) -> void:
	root_aabb = aabb
	chunk_size = chunk_size_in
	max_depth = max_depth_in
	_nodes.clear()
	_add_node(root_aabb, 0)

func refine_region(request_aabb: AABB) -> void:
	if not root_aabb.intersects(request_aabb):
		return
	var changed := true
	while changed:
		changed = false
		var keys := _nodes.keys()
		for key in keys:
			if not _nodes.has(key):
				continue
			var node: Dictionary = _nodes[key]
			if node["depth"] >= max_depth:
				continue
			var node_aabb: AABB = node["aabb"]
			if not node_aabb.intersects(request_aabb):
				continue
			var children: Array[Dictionary] = _create_children(node)
			if children.is_empty():
				continue
			_nodes.erase(key)
			for child in children:
				_add_node(child["aabb"], child["depth"])
			changed = true
			break

func derefine_region(request_aabb: AABB) -> void:
	if _nodes.size() <= 1:
		return
	var to_remove: Array[String] = []
	var parent_counts := Dictionary()
	var parent_infos := Dictionary()
	for key in _nodes.keys():
		var node: Dictionary = _nodes[key]
		if node["depth"] == 0:
			continue
		var node_aabb: AABB = node["aabb"]
		if not node_aabb.intersects(request_aabb):
			continue
		to_remove.append(key)
		var parent: Dictionary = _parent_info(node)
		if parent.is_empty():
			continue
		var pkey: String = parent["key"]
		var count: int = int(parent_counts.get(pkey, 0)) + 1
		parent_counts[pkey] = count
		if not parent_infos.has(pkey):
			parent_infos[pkey] = parent
	for key in to_remove:
		_nodes.erase(key)
	_remove_voxel_values_outside([request_aabb])
	for pkey in parent_counts.keys():
		if int(parent_counts[pkey]) >= 8 and parent_infos.has(pkey):
			var parent: Dictionary = parent_infos[pkey]
			_add_node(parent["aabb"], parent["depth"])

func prune_outside(regions: Array) -> void:
	if regions.is_empty():
		_nodes.clear()
		_add_node(root_aabb, 0)
		_voxel_values.clear()
		return
	var to_remove: Array[String] = []
	var parent_counts := Dictionary()
	var parent_infos := Dictionary()
	for key in _nodes.keys():
		var node: Dictionary = _nodes[key]
		if node["depth"] == 0:
			continue
		var node_aabb: AABB = node["aabb"]
		if not _intersects_any(node_aabb, regions):
			continue
		to_remove.append(key)
		var parent: Dictionary = _parent_info(node)
		if parent.is_empty():
			continue
		var pkey: String = parent["key"]
		var count: int = int(parent_counts.get(pkey, 0)) + 1
		parent_counts[pkey] = count
		if not parent_infos.has(pkey):
			parent_infos[pkey] = parent
	for key in to_remove:
		_nodes.erase(key)
		_remove_voxel_values_outside(regions)
		for pkey in parent_counts.keys():
			if int(parent_counts[pkey]) >= 8 and parent_infos.has(pkey):
				var parent: Dictionary = parent_infos[pkey]
				_add_node(parent["aabb"], parent["depth"])
		_remove_voxel_values_outside(regions)

func set_voxel(_global_position: Vector3, _value: float) -> void:
	var region := _make_brush_region(_global_position)
	refine_region(region)
	var key := _make_voxel_key(_global_position)
	_voxel_values[key] = {
		"value": _value,
	}

func clear_voxel(_global_position: Vector3) -> void:
	var key := _make_voxel_key(_global_position)
	_voxel_values.erase(key)
	var region := _make_brush_region(_global_position)
	derefine_region(region)

func get_voxel_values() -> Dictionary:
	return _voxel_values.duplicate()

func query_nodes(region: AABB) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for key in _nodes.keys():
		var node: Dictionary = _nodes[key]
		var node_aabb: AABB = node["aabb"]
		if not region.intersects(node_aabb):
			continue
		var entry := node.duplicate(true)
		entry["key"] = key
		results.append(entry)
	return results

func get_nodes() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for key in _nodes.keys():
		var node: Dictionary = _nodes[key]
		var entry := node.duplicate(true)
		entry["key"] = key
		results.append(entry)
	return results

func _add_node(aabb: AABB, depth: int) -> void:
	var key := _make_key(aabb, depth)
	if _nodes.has(key):
		return
	_nodes[key] = {"aabb": aabb, "depth": depth}

func _create_children(node: Dictionary) -> Array[Dictionary]:
	var depth: int = node["depth"] + 1
	if depth > max_depth:
		return []
	var parent_aabb: AABB = node["aabb"]
	var half := parent_aabb.size * 0.5
	var min_size := Vector3(chunk_size.x, chunk_size.y, chunk_size.z)
	if half.x < min_size.x or half.y < min_size.y or half.z < min_size.z:
		return []
	var children: Array[Dictionary] = []
	for x in range(2):
		for y in range(2):
			for z in range(2):
				var offset := Vector3(x, y, z)
				var child_origin := parent_aabb.position + half * offset
				var child_aabb := AABB(child_origin, half)
				children.append({"aabb": child_aabb, "depth": depth})
	return children

func _parent_info(node: Dictionary) -> Dictionary:
	var depth: int = node["depth"]
	if depth <= 0:
		return {}
	var child_aabb: AABB = node["aabb"]
	var parent_depth := depth - 1
	var parent_size := child_aabb.size * 2.0
	var snapped_origin := child_aabb.position.snapped(parent_size)
	var parent_aabb := AABB(snapped_origin, parent_size)
	var key := _make_key(parent_aabb, parent_depth)
	return {"key": key, "aabb": parent_aabb, "depth": parent_depth}

func _make_key(aabb: AABB, depth: int) -> String:
	return "%d|%.4f|%.4f|%.4f|%.4f|%.4f|%.4f" % [
		depth,
		aabb.position.x,
		aabb.position.y,
		aabb.position.z,
		aabb.size.x,
		aabb.size.y,
		aabb.size.z
	]

func _intersects_any(aabb: AABB, regions: Array) -> bool:
	for region in regions:
		if region is AABB and aabb.intersects(region):
			return true
	return false

func _make_brush_region(global_position: Vector3) -> AABB:
	var half := Vector3(chunk_size.x, chunk_size.y, chunk_size.z) * 0.5
	if half == Vector3.ZERO:
		half = Vector3.ONE
	return AABB(global_position - half, half * 2.0)

func _make_voxel_key(global_position: Vector3) -> String:
	var local := global_position - root_aabb.position
	var cell := Vector3i(
		int(floor(local.x / max(1, chunk_size.x))),
		int(floor(local.y / max(1, chunk_size.y))),
		int(floor(local.z / max(1, chunk_size.z)))
	)
	return "%d|%d|%d" % [cell.x, cell.y, cell.z]

func _remove_voxel_values_outside(regions: Array) -> void:
	if regions.is_empty():
		_voxel_values.clear()
		return
	var remaining: Dictionary = {}
	for key in _voxel_values.keys():
		var record: Dictionary = _voxel_values[key]
		var position: Vector3 = record.get("position", Vector3.ZERO)
		if _position_in_regions(position, regions):
			remaining[key] = record
	_voxel_values = remaining

func _position_in_regions(position: Vector3, regions: Array) -> bool:
	for region in regions:
		if region is AABB and region.has_point(position):
			return true
	return false
