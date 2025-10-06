extends Node3D

@export var move_speed: float = 10.0
@export var mouse_sensitivity: float = 0.005
@export var indicator_height: float = 2.0
@export var moving_color: Color = Color(0.2, 1.0, 0.2, 1.0)
@export var idle_color: Color = Color(1.0, 0.8, 0.2, 1.0)
var _camera: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _indicator: Label3D

func _ready() -> void:
	_camera = get_node_or_null("Camera3D")
	_yaw = rotation.y
	if _camera:
		_pitch = _camera.rotation.x
	_ensure_wasd_bindings()
	_capture_mouse()
	_setup_indicator()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var movement_basis := Basis(Vector3.UP, _yaw)
	var move_vector := (movement_basis.z * -input_dir.y) + (movement_basis.x * input_dir.x)
	if move_vector.length() > 0.001:
		translate(move_vector.normalized() * move_speed * delta)
	_update_indicator(move_vector, delta)
func _setup_indicator() -> void:
	_indicator = Label3D.new()
	_indicator.name = "MovementIndicator"
	_indicator.position = Vector3(0.0, indicator_height, 0.0)
	_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicator.double_sided = true
	_indicator.modulate = idle_color
	_indicator.text = "Idle"
	_indicator.pixel_size = 0.01
	add_child(_indicator)

func _update_indicator(move_vector: Vector3, _delta: float) -> void:
	if _indicator == null:
		return
	var velocity := move_vector.length() * move_speed
	var is_moving := velocity > 0.01
	if is_moving:
		_indicator.text = "Moving (%.1f)" % velocity
		_indicator.modulate = moving_color
	else:
		_indicator.text = "Idle"
		_indicator.modulate = idle_color
	_indicator.position = Vector3(0.0, indicator_height, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-80), deg_to_rad(80))
		rotation = Vector3(0.0, _yaw, 0.0)
		if _camera:
			_camera.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_capture_mouse()

func reset_mouse_capture() -> void:
	_capture_mouse()

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ensure_wasd_bindings() -> void:
	var mapping := {
		"ui_up": Key.KEY_W,
		"ui_down": Key.KEY_S,
		"ui_left": Key.KEY_A,
		"ui_right": Key.KEY_D,
	}
	for action in mapping.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.keycode = mapping[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
