extends Spatial

class_name WeaponGuidance

signal __armament_fired(guidance)
signal __armament_detonated(guidance)

var _velocity := 0.0
var _transform := Transform()
var _barrel := Vector3.ZERO
var _direction := Vector3.ZERO
var _use_physics_process := true
var _projectile_scene: PackedScene = null
var _projectile: Spatial = null
var _green_light := false
var _arm_time := 0.3
var _armed := false

func _process(delta):
	if not _use_physics_process and _green_light:
		_guide(delta)

func _physics_process(delta):
	if _use_physics_process and _green_light:
		_guide(delta)

func _guide(delta: float):
	pass

func _start(move := true):
	if move:
		global_translate(_barrel - global_transform.origin)
	look_at(_direction, Vector3.UP)
	_projectile = _projectile_scene.instance()
	add_child(_projectile)
	_projectile.translation = Vector3.ZERO
	_projectile.look_at(global_transform.origin + _direction, Vector3.UP)
	_signals_init()
	_initialize()
	_green_light = true

func _signals_init():
	if _projectile.has_method("arm_launched"):
		connect("__armament_fired", _projectile, "arm_launched")
	if _projectile.has_method("arm_arrived"):
		connect("__armament_detonated", _projectile, "arm_arrived")

func _initialize():
	emit_signal("__armament_fired", self)

func _finalize():
	_green_light = false
	emit_signal("__armament_detonated", self)
	_clean()

func _clean():
#	if not _projectile:
#		return
#	var p_parent := _projectile.get_parent()
#	if p_parent:
#		p_parent.remove_child(_projectile)
#	_projectile.free()
	queue_free()
