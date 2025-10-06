extends Node

var player_count: int = 0

var _logger: Node

func _ready() -> void:
	_logger = get_node_or_null("/root/Logger")
	_log_info("GameState initialized", {
		"player_count": player_count,
	})

func set_player_count(value: int) -> void:
	player_count = value
	_log_debug("Player count updated", {
		"player_count": player_count,
	})

func _log_info(message: String, extra: Dictionary = {}) -> void:
	if _logger and _logger.has_method("log_info"):
		_logger.call("log_info", message, extra)
	else:
		print("[INFO] %s" % message)

func _log_debug(message: String, extra: Dictionary = {}) -> void:
	if _logger and _logger.has_method("log_debug"):
		_logger.call("log_debug", message, extra)
	else:
		print("[DEBUG] %s" % message)
