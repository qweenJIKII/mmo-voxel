extends Node3D

class_name MainRoot

@export var world_root: NodePath

var _logger: Node
var _config_service: Node
var _network_client: Node

func _ready() -> void:
	_logger = get_node_or_null("/root/Logger")
	_config_service = get_node_or_null("/root/ConfigService")
	_network_client = get_node_or_null("/root/NetworkClient")
	_apply_configuration()
	_log_info("MainRoot ready", {
		"world_root": world_root,
	})

func _apply_configuration() -> void:
	if _config_service == null or _network_client == null:
		return
	var host := "127.0.0.1"
	var port := 4242
	if _network_client.has_method("get"):
		var existing_host: Variant = _network_client.get("host")
		if existing_host != null:
			host = str(existing_host)
		var existing_port: Variant = _network_client.get("port")
		if existing_port != null:
			port = int(existing_port)
	if _config_service and _config_service.has_method("get_setting"):
		host = str(_config_service.call("get_setting", "network.host", host))
		port = int(_config_service.call("get_setting", "network.port", port))
	if _network_client and _network_client.has_method("configure"):
		_network_client.call("configure", host, port)
	_log_debug("Network client configured", {
		"host": host,
		"port": port,
	})

func _log_info(message: String, data: Dictionary = {}) -> void:
	if _logger and _logger.has_method("log_info"):
		_logger.call("log_info", message, data)
	else:
		print("[INFO] %s" % message)

func _log_debug(message: String, data: Dictionary = {}) -> void:
	if _logger and _logger.has_method("log_debug"):
		_logger.call("log_debug", message, data)
	else:
		print("[DEBUG] %s" % message)
