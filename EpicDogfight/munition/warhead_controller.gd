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
export var damage_modifier: Resource = null
export var effect_1: Resource = null
export var effect_2: Resource = null
export var effect_3: Resource = null

onready var allow_damage: bool = SingletonManager.static_services["UtilsSettings"].allow_damage
onready var explosion_ref: Spatial = get_node_or_null(explosion)
onready var aoec_ref: Area = get_node_or_null(aoe_collider)
onready var wc_ref: Area = get_node_or_null(warhead_collider)
onready var tree := get_tree()

var last_speed := 0.0

func projectile_crash(speed: float):
	translation -= Vector3(0.0, 0.0, speed * impact_speed_reduction)

func play():
	if delay_time > 0.0:
		yield(Out.timer(delay_time), "timeout")
	Utilities.TrialTools.try_set(explosion_ref, "animation_lifetime", \
		explosion_lifetime)
	Utilities.TrialTools.try_call(explosion_ref, "make_kaboom")
	if not inert and allow_damage:
		distribute_damage()
	_finalize()

func get_effects() -> Array:
	var re := []
	if effect_1 != null:
		re.append(effect_1)
	if effect_2 != null:
		re.append(effect_2)
	if effect_3 != null:
		re.append(effect_3)
	return re

func distribute_damage():
	var effect_list := get_effects()
	var bodies: Array = Utilities.TrialTools.try_call(aoec_ref, "get_overlapping_bodies", \
		[], [])
	for b in bodies:
		if b is Combatant:
			if b._controller is WeaponGuidance:
				b._controller._finalize()
				continue
			var request := DamageRequest.new(b, base_damage, damage_modifier, \
				effect_list)
			CombatServer.CombatMiddleman.damage(request)

func _finalize():
	if explosion_lifetime > 0.0:
		yield(Out.timer(explosion_lifetime), "timeout")
	emit_signal("__warhead_finalized")
