extends Node

const DEFAULT_CONFIG_PATH := "res://config/default_config.json"

var settings: Dictionary = {}

func _ready() -> void:
	# 起動時にデフォルト設定を読み込み
	load_config(DEFAULT_CONFIG_PATH)

func load_config(path: String) -> void:
	# 設定ファイルを読み込み、settings に保持
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ConfigService: failed to load config: %s" % path)
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_warning("ConfigService: invalid JSON in %s" % path)
		return
	settings = json.data if typeof(json.data) == TYPE_DICTIONARY else {}

func get_setting(key: String, default_value: Variant = null) -> Variant:
	# ドット区切りキーで設定値を取得
	if key.is_empty():
		return default_value
	var current: Variant = settings
	var tokens := key.split(".")
	for token in tokens:
		if typeof(current) != TYPE_DICTIONARY or not current.has(token):
			return default_value
		current = current[token]
	return current
