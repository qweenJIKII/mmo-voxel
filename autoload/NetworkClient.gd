extends Node

var host: String = "127.0.0.1"
var port: int = 4242
var connected: bool = false

func _ready() -> void:
	# TODO: ENet クライアント初期化を実装
	pass

func configure(_host: String, _port: int) -> void:
	host = _host
	port = _port

func connect_to_server() -> void:
	# TODO: ENet 接続処理を追加
	connected = false

func disconnect_from_server() -> void:
	# TODO: ENet 切断処理を追加
	connected = false
