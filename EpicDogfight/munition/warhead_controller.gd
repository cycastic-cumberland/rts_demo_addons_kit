extends Spatial

class_name WarheadController

signal __warhead_finalized()

export(NodePath) var explosion: NodePath = ""
export(NodePath) var aoe_collider: NodePath = ""
export(NodePath) var warhead_collider: NodePath = ""
export(bool) var inert := false
export(float, 0.0, 10000.0) var base_damage := 10.0
export(float, 0.0, 1.0) var impact_speed_reduction := 0.3
export(float, 0.0, 100.0) var delay_time := 0.0
export(float, 0.0, 100.0) var explosion_lifetime := 0.0
export var effector_1: Resource = null
export var effector_2: Resource = null
export var effector_3: Resource = null

var safety := true

onready var allow_damage: bool = SingletonManager.static_services["UtilsSettings"].allow_damage
onready var explosion_ref: Spatial = get_node_or_null(explosion)
onready var aoec_ref: Area = get_node_or_null(aoe_collider)
onready var wc_ref: Area = get_node_or_null(warhead_collider)
onready var tree := get_tree()

var last_transform := Transform()
var damage_mod: DamageModifiersConfiguration = null
var last_speed := 0.0
var last_position := Vector3.ZERO
var last_fwd_vec := Vector3.ZERO

func on_peripherals_pool_entered(_ppool):
#	visible = false
	# transform = last_transform
#	translation = last_position + \
#		(last_fwd_vec * last_speed * impact_speed_reduction)
#	look_at(translation + last_fwd_vec, Vector3.UP)
	if safety:
		return
	play()

func play():
	if delay_time > 0.0:
		yield(Out.timer(delay_time), "timeout")
	Toolkits.TrialTools.try_set(explosion_ref, "animation_lifetime", \
		explosion_lifetime)
	Toolkits.TrialTools.try_call(explosion_ref, "make_kaboom")
	if not inert and allow_damage:
		distribute_damage()
	_finalize()

func get_effectors() -> Array:
	var re := []
	if effector_1 != null:
		re.append(effector_1)
	if effector_2 != null:
		re.append(effector_2)
	if effector_3 != null:
		re.append(effector_3)
	return re

func distribute_damage():
	var effector_list := get_effectors()
	var bodies: Array = Toolkits.TrialTools.try_call(aoec_ref, "get_overlapping_bodies", \
		[], [])
	for b in bodies:
		if b is Combatant:
			var request := DamageRequest.new(b, base_damage, damage_mod, \
				effector_list)
			CombatServer.CombatMiddleman.damage(request)

func _finalize():
	emit_signal("__warhead_finalized")
