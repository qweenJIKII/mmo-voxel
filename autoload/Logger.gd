extends Node

var enable_jsonl: bool = true
var log_level: String = "info"
var _config_service: Node
var _log_file: FileAccess

func _ready() -> void:
	# ConfigService から設定を取得
	_config_service = get_node_or_null("/root/ConfigService")
	if _config_service and _config_service.has_method("get_setting"):
		enable_jsonl = bool(_config_service.call("get_setting", "logging.enable_jsonl", true))
		log_level = str(_config_service.call("get_setting", "logging.log_level", "info"))
	if enable_jsonl:
		_open_log_file()
	log_info("Logger initialized")

func _open_log_file() -> void:
	var logs_dir := "user://logs"
	DirAccess.make_dir_recursive_absolute(logs_dir)
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/session-%s.jsonl" % [logs_dir, timestamp]
	_log_file = FileAccess.open(path, FileAccess.WRITE)
	if _log_file == null:
		push_warning("Logger: failed to open log file")

func log_debug(message: String, extra: Dictionary = {}) -> void:
	_log("debug", message, extra)

func log_info(message: String, extra: Dictionary = {}) -> void:
	_log("info", message, extra)

func log_error(message: String, extra: Dictionary = {}) -> void:
	_log("error", message, extra)

func _log(level: String, message: String, extra: Dictionary) -> void:
	if not enable_jsonl:
		print("[%s] %s" % [level.to_upper(), message])
		return
	if _log_file == null:
		return
	var payload := {
		"ts": Time.get_unix_time_from_system(),
		"level": level,
		"message": message,
		"extra": extra,
	}
	_log_file.store_line(JSON.stringify(payload))
	_log_file.flush()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _log_file:
		_log_file.close()
