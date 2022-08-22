extends Spatial

class_name MunitionController

const WC_DEFAULT_SIGNALS := {
	"area_entered": "premature_detonation_handler"
}
const WH_DEFAULT_SIGNALS := {
	"__warhead_finalized": "_clean"
}
const AUTO_FREE_INTERVAL := 1.0 * 60.0

export(NodePath) var warhead := "" setget set_whh
export(NodePath) var particles_holder := "" setget set_phh
export(Resource)var damage_modifier = null

var warhead_ref: WarheadController = null setget set_warhead
var ph_ref: Spatial = null setget set_ph

var detonated := false
var is_ready := false
var max_lifetime := 0.0
var particles_list := []
var deliver: VTOLFighterBrain = null
var guidance: WeaponGuidance = null
var _ref: InRef = null

# Exports set/get
func set_whh(wh: String):
	warhead = wh
	if not is_ready:
		return
	var path := wh
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is WarheadController:
		Out.print_error("Referenced node must be of type: Area", get_stack())
	set_warhead(c)

func set_phh(ph: String):
	particles_holder = ph
	if not is_ready:
		return
	var path := ph
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is Spatial:
		Out.print_error("Referenced node must be of type: Spatial", get_stack())
	set_ph(c)

# Main set/get
func set_warhead(wh: WarheadController):
	var old_warhead := warhead_ref
	if old_warhead != null:
		Toolkits.SignalTools.disconnect_from(warhead_ref, self, WH_DEFAULT_SIGNALS)
		var collider = old_warhead.wc_ref
		Toolkits.SignalTools.disconnect_from(collider, self , \
			WC_DEFAULT_SIGNALS, false)
	warhead_ref = wh
	Toolkits.SignalTools.connect_from(warhead_ref, self, WH_DEFAULT_SIGNALS)
	Toolkits.SignalTools.connect_from(warhead_ref.wc_ref, self , \
		WC_DEFAULT_SIGNALS, false, false)

func set_ph(ph: Spatial):
	ph_ref = ph
	particles_list = []
	var children := ph.get_children()
	for c in children:
		if c is Particles:
			particles_list.append(c)
			if c.lifetime > max_lifetime:
				max_lifetime = c.lifetime
		continue

func _ready():
	is_ready = true
	_ref = InRef.new(self)
	_ref.add_to("munition_controllers")
	set_whh(warhead)
	# if warhead_ref:
	# 	 max_lifetime = \
	# 	 	max(warhead_ref.delay_time, warhead_ref.explosion_lifetime)
	set_phh(particles_holder)

func __is_projectile():
	return true

func arm_launched(g: WeaponGuidance):
	guidance = g
	g._autofree_projectile = false
	if g is HomingGuidance:
		deliver = g.vtol
	_start()

func arm_arrived(_g: WeaponGuidance):
	_finalize()

func premature_detonation_handler(_area):
	guidance._finalize()

func set_particle_emit(a: bool):
	for p in particles_list:
		p.emitting = a

func _start():
	guidance._armed = true

var autofree_timer: SceneTreeTimer = null

func _finalize():
	detonated = true
	max_lifetime += Toolkits.TrialTools.try_get(warhead_ref, "delay_time", 0.0)
	Toolkits.TrialTools.try_set(warhead_ref, "wc_ref.monitoring", false, true)
	var children := get_children()
	for child in children:
		if child == warhead_ref or child == ph_ref:
			continue
		child.visible = false
	set_particle_emit(false)
	var exp_lifetime := max_lifetime
	if warhead_ref != null:
		warhead_ref.play()
		exp_lifetime = warhead_ref.explosion_lifetime
	yield(Out.timer(exp_lifetime + 0.0), "timeout")
	Toolkits.TrialTools.try_call(ph_ref, "queue_free")
	autofree_timer = Out.timer(AUTO_FREE_INTERVAL)
	yield(autofree_timer, "timeout")
	autofree_timer = null
	_clean()
	# Toolkits.TrialTools.try_call(deliver, "queue_free")
	# queue_free()

func _clean():
	while not Toolkits.TrialTools.try_call(ph_ref, "is_queued_for_deletion", \
		[], true):
			yield(get_tree(), "idle_frame")
	if autofree_timer != null:
		Toolkits.SignalTools.disconnect_all(autofree_timer)
	Toolkits.TrialTools.try_call(deliver, "queue_free")
	queue_free()
