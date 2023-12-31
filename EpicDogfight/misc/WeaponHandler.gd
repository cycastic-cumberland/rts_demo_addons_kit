extends Spatial

class_name WeaponHandler

signal __out_of_ammo(handler)
signal __fired(handler)

const TIMER_ROLLBACK	:= 3600.0

export(NodePath) var handling_fighter := NodePath()
#onready var _fighter: AirCombatant = get_node_or_null(handling_fighter)

var use_physics_process: bool = SingletonManager.fetch("UtilsSettings").use_physics_process
var override_compensation := false
var compensator_autosetup := false
var compensation := 0.0

var weapon_name := ""
var profile: WeaponConfiguration = null setget set_profile, get_profile
var compensator: DistanceCompensatorV2 = null
var carrier: Combatant = null
var target: Spatial = null
var hardpoints := []
var hardpoints_last_fire: PoolRealArray = []
var hardpoints_activation: PoolIntArray = [] # 1 is activated, other is not
var angle_limit := deg2rad(1.0)
var pgm_target := Vector3.ZERO

var current_fire_mode: int = WeaponConfiguration.FIRE_MODE.BARRAGE
var reserve := 0
var loading_time := 1.0
var charge_rate := 0.0
var last_hardpoint := -1
var inherit_carrier_speed := true
var guided := true

var timer := 0.0
var green_light := false

func set_profile(p: WeaponConfiguration):
	profile = p
	weapon_name = p.weapon_name
	reserve = p.rounds
	loading_time = p.loadingTime
	current_fire_mode = profile.weaponFireMode

func get_profile():
	return profile

func set_hardpoints(h_list := []):
	var last_fire := timer
	var num := h_list.size()
	hardpoints.clear()
	hardpoints_last_fire.resize(num)
	hardpoints_activation.resize(num)
	hardpoints.resize(num)
	for c in range(0, num):
		if h_list.empty():
			hardpoints[c] = null
		else:
			hardpoints[c] = h_list[c]
		hardpoints_last_fire[c] = last_fire
		hardpoints_activation[c] = 1

func get_hardpoint(loc: int):
	return hardpoints[clamp(loc, 0, hardpoints.size() - 1)]

func get_last_hardpoint():
	return get_hardpoint(last_hardpoint)

func angle_check():
	var no := 0
	if last_hardpoint >= hardpoints.size() or last_hardpoint <= 0:
		no = 0
	var current_hardpoint: Spatial = hardpoints[no]
	var direction := -current_hardpoint.global_transform.basis.z
	var target_dir: Vector3 = current_hardpoint.direction_to(target)
	if target_dir.angle_to(direction) <= angle_limit:
		return true
	return false

func clear_for_fire() -> bool:
	if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		if compensation <= profile.travelTime:
			if angle_check():
				return true
			else:
				return false
		else:
			return false
	else:
		var distance: float = hardpoints[last_hardpoint].global_transform.origin\
			.distance_to(target.global_transform.origin)
		if distance <= profile.homingRange:
			if angle_check():
				return true
			else:
				return false
		else:
			return false

func guidance_instancing(g: WeaponGuidance):
	# Would most likely cause some problems later on
	LevelManager.template.add_peripheral(g)
	while not g.get_parent():
		yield(get_tree(), "idle_frame")
	return true

func spawn_projectile(no: int):
	var guidance: WeaponGuidance
	var instancing_result
	# For dumb munitions
	if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		guidance = DumbGuidance.new()
		instancing_result = guidance_instancing(guidance)
		var max_travel_time: float = profile.travelTime
		var actual_comp := 0.0
		if override_compensation:
			actual_comp = compensation
		else:
			actual_comp = compensator.compensation
		guidance.detonation_time = clamp(actual_comp, 0.0, max_travel_time)
	# For HomingGuidance and all of its inheritances
	else:
		if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.SEMI\
			or profile.weaponGuidance == WeaponConfiguration.GUIDANCE.ACTIVE:
			guidance = HomingGuidance.new()
		elif profile.weaponGuidance == WeaponConfiguration.GUIDANCE.FLG:
			guidance = ForwardLookingGuidance.new()
		elif profile.weaponGuidance == WeaponConfiguration.GUIDANCE.IHG:
			guidance = IntegratedHomingGuidance.new()
		elif profile.weaponGuidance == WeaponConfiguration.GUIDANCE.PRECISION:
			guidance = PrecisionGuidance.new()
			guidance.site = pgm_target
		if inherit_carrier_speed and carrier != null:
			guidance.inherited_speed = carrier.currentSpeed
		guidance.target = target
		guidance.handler = self
		instancing_result = guidance_instancing(guidance)
	# if instancing_result is bool:
	# 	if not instancing_result:
	# 		Out.print_error("Failed to instance guidance", get_stack())
	# 		return
	var curr_hardpoint: Spatial = hardpoints[no]
	var hp_loc := curr_hardpoint.global_transform.origin
	var fwd_vec := -curr_hardpoint.global_transform.basis.z
	var euler := curr_hardpoint.global_transform.basis.get_euler()
	guidance._arm_time = profile.weaponArmTime
	guidance._barrel = hp_loc
	guidance._weapon_base_config = profile
	guidance._direction = fwd_vec
	while not guidance.get_parent():
		yield(get_tree(), "idle_frame")
	guidance._guidance_init()
	guidance.switch_on()

func is_out_of_ammo() -> bool:
	if reserve <= 0:
		emit_signal("__out_of_ammo", self)
		return true
	else:
		return false

func fire_once(delta := 0.0):
	if hardpoints.size() == 0:
		return
	var last_fire := timer
	var is_fired := false
	if current_fire_mode == WeaponConfiguration.FIRE_MODE.SALVO:
		var hardpoints_count = hardpoints.size()
		for c in range(0, hardpoints_count):
			if hardpoints_activation[c] != 1:
				continue
			elif is_out_of_ammo():
				return
			var time_elapsed := abs(last_fire - hardpoints_last_fire[c])
			if time_elapsed > loading_time:
				spawn_projectile(c)
				hardpoints_last_fire[c] = last_fire
				reserve -= 1
				is_fired = true
	elif current_fire_mode == WeaponConfiguration.FIRE_MODE.BARRAGE:
		if is_out_of_ammo():
			return
		var current_hardpoint: int = wrapi(last_hardpoint + 1, 0, hardpoints.size())
#		if current_hardpoint >= hardpoints.size():
#			current_hardpoint = 0
		if hardpoints_activation[current_hardpoint] != 1:
			return
		var time_elapsed := abs(last_fire -\
			hardpoints_last_fire[current_hardpoint])
		if time_elapsed > loading_time:
			spawn_projectile(current_hardpoint)
			hardpoints_last_fire[current_hardpoint] = last_fire
			last_hardpoint = current_hardpoint
			reserve -= 1
			is_fired = true
#		else:
#			current_hardpoint -= 1
	if is_fired:
		emit_signal("__fired", self)

func fire():
	green_light = not green_light

func setup():
	compensator = DistanceCompensatorV2.new()
	compensator.target = target
	compensator.barrel = carrier
	compensator.profile.projectile_speed = profile.travelSpeed
	LevelManager.template.add_peripheral(compensator)

func reset_hardpoints_info():
	var children := get_children()
	if children == []:
		set_hardpoints([self])
	else:
		set_hardpoints(children)

func _ready():
	reset_hardpoints_info()
	carrier = get_node_or_null(handling_fighter)
	if compensator_autosetup:
		setup()

func _process(delta):
	if not use_physics_process and green_light:
		fire_once(delta)
	timer += delta
	if timer > TIMER_ROLLBACK:
		timer = 0.0

func _physics_process(delta):
	if use_physics_process and green_light:
		fire_once(delta)
