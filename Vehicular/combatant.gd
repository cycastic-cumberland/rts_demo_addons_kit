extends KinematicBody

class_name Combatant

signal __combatant_out_of_hp(combatant)

const FORE					= PI
const AFT					= -FORE
const HARD_PORT				= PI / 2.0
const HARD_STARBOARD		= -HARD_PORT

# Exports
export(NodePath) var fire_control := ""
export(NodePath) var navigation_agent := ""

# Settings
var _disabled := false setget set_disabled
var _trackable := true
var _use_navagent := true
var _controller = null
var _trackedBy = null
var _ref: InRef = null
var _vehicle_config: CombatantConfiguration = null setget set_config
var _use_physics_process: bool = SingletonManager.fetch("UtilsSettings").use_physics_process \
	setget set_pp

# Data
var _heat_signature := 10.0
var nav_agent: NavigationAgent = null
var hp := 100.0
var currentSpeed := 0.0
var last_delta := 0.0

var hardpoints := {
	"PRIMARY":		[],
	"SECONDARY":	[],
}

func _init():
	process_switch()

func _ready():
	var na := get_node_or_null(navigation_agent)
	if na == null:
		return
	if na is NavigationAgent:
		nav_agent = na
	else:
		Out.print_error("Assigned Node is not a NavigationAgent", get_stack())

func get_fire_control():
	var fc = get_node_or_null(fire_control)
#	if fc is WeaponHandler:
#		return fc
#	else:
#		return null
	return fc

func process_switch():
	set_process(not _disabled and not _use_physics_process)
	set_physics_process(not _disabled and _use_physics_process)

func set_disabled(d: bool):
	_disabled = d
	process_switch()

func set_pp(pp: bool):
	_use_physics_process = pp
	process_switch()

func set_config(cfg):
	_vehicle_config = cfg

# Outdated
func _process(delta):
	pass

func _damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		emit_signal("__combatant_out_of_hp", self)

func _damage_over_time(total: float, duration: float) -> void:
	if duration <= 0.0:
		Out.print_error("Duration must be above 0", get_stack())
	var dps := total / duration
	var damage_per_turn: float = dps * last_delta
	while total > 0.0:
		total -= damage_per_turn
		_damage(damage_per_turn)
		if hp <= 0.0:
			break
		yield(get_tree(), "idle_frame")

