extends Node

signal __changing_to_scene(to)
signal __template_changed()

const LEVEL_TEMPLATE_SOURCE := preload("level_template/level_template.tscn")

var template: LevelTemplate = null setget set_template, get_template
var instructions := {}
var oneshot_singletons := []
var preloaded := []
var curr_lmac: LM_AssistClass = null

class LM_AssistClass extends Reference:
	signal __finished_all()
	signal __loading_percentage(percent)
	signal __lmac_finished()
	signal __change_next_frame(to)

	var curr_template: LevelTemplate = null

	var lspc: AssetsPreloader = null
	var mpc: AssetsPreloader = null
	var tree: SceneTree = null
	var loading_scene = null
	var main_scene_packed = null

	var ls_status := false
	var main_status := false

	var current_main_stage := 0
	var current_pl_stage := 0
	var total_stages := 0

	func _init(t: SceneTree):
		tree = t
		curr_template = tree.current_scene
		connect("__finished_all", self, "load_main_finished_handler")

	static func load_singleton(s_dict: Dictionary):
		var oneshot := false
		if not s_dict.has_all(["name", "path"]):
			Out.print_error("Singleton config does not have name and/or path", \
				get_stack())
			return
		if s_dict.has("is_oneshot"):
			oneshot = s_dict["is_oneshot"]
		SingletonManager.add_singleton_from_script(s_dict["path"], s_dict["name"])
		if oneshot:
			LevelManager.oneshot_singletons.append(s_dict["name"])

	static func setup_autoloads(s_list: Array):
		for single in s_list:
			load_singleton(single)

	func defer_loading_scene(path: String) -> AssetsPreloader:
		var preload_com := AssetsPreloader.new(tree)
		preload_com.load_assets([path])
		return preload_com

	func spawn_loading_scene(path: String):
		if not ResourceLoader.exists(path):
			Out.print_warning("Loading scene not exists: " + path, \
				get_stack())
			ls_status = true
			return
		lspc = defer_loading_scene(path)
		lspc.connect("__finished_loading", self, "loading_scene_finished_loading")

	func loading_scene_finished_loading(preloader):
		loading_scene = preloader.assets[0].instance()
		# tree.current_scene.add_child(loading_scene)
		curr_template.add_scene(loading_scene, false)
		if loading_scene.has_method("change_percentage"):
		   connect("__loading_percentage", loading_scene, "change_percentage")
		ls_status = true

	func load_main(scene_path: String, p_list: PoolStringArray):
		if not ResourceLoader.exists(scene_path):
			Out.print_error("Main scene not exists: " + scene_path, \
				get_stack())
			main_status = true
			return
		while not ls_status:
			yield(tree, "idle_frame")
		mpc = AssetsPreloader.new(tree)
		var load_inter := ResourceLoader.load_interactive(scene_path, "PackedScene")
		total_stages += load_inter.get_stage_count()
		total_stages += p_list.size()
		mpc.load_assets(p_list)
		main_handler(load_inter)
		preload_handler(mpc)
		percentage_handler()

	func percentage_handler():
		while not main_status:
			var percent: float = float(current_main_stage + current_pl_stage) / float(total_stages)
			emit_signal("__loading_percentage", percent)
			if main_scene_packed != null and mpc.finished_loading:
				if loading_scene != null:
					var l_parent = loading_scene.get_parent()
					if is_instance_valid(l_parent):
						l_parent.remove_child(loading_scene)
					loading_scene.queue_free()
				emit_signal("__change_next_frame", main_scene_packed)
				# yield(tree, "idle_frame")
				# var curr_scene := tree.current_scene
				# curr_scene.queue_free()
				# tree.change_scene_to(main_scene_packed)
				var new_main = main_scene_packed.instance()
				curr_template.add_scene(new_main, false)

				emit_signal("__finished_all")
				break
			yield(tree, "idle_frame")

	func main_handler(load_inter: ResourceInteractiveLoader):
		while true:
			var err := load_inter.poll()
			if err == OK:
				current_main_stage = load_inter.get_stage()
			elif err == ERR_FILE_EOF:
				main_scene_packed = load_inter.get_resource()
				current_main_stage = load_inter.get_stage_count()
				break
			else:
				break
			yield(tree, "idle_frame")

	func preload_handler(preloader: AssetsPreloader):
		while not preloader.finished_loading:
			current_pl_stage = preloader.loaded
			yield(tree, "idle_frame")

	func load_main_finished_handler():
		LevelManager.preloaded = mpc.assets
		main_status = true
		emit_signal("__lmac_finished")

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	connect("__template_changed", self, "template_change_handler")

func set_template(t):
	return

func get_template(reset := false) -> LevelTemplate:
	if reset:
		template = get_tree().current_scene
	# if not scene is LevelTemplate:
	# 	return null
	return template

func level2package(which: Node) -> PackedScene:
	get_tree().paused = true
	var package := PackedScene.new()
	package.pack(which)
	get_tree().paused = false
	return package

func serialize_level(which := template) -> String:
	var serialized := var2str(level2package(which))
	return serialized

func save_level(path: String):
	var SAVE_FILE_PASSWORD := "%SFPWD_V0001%"
	var password := ""
	if SAVE_FILE_PASSWORD[0] != "%" and SAVE_FILE_PASSWORD.right(0) != "%":
		password = SAVE_FILE_PASSWORD
	var packed := serialize_level()
	var f := File.new()
	f.open_encrypted_with_pass(path, File.WRITE, password)
	f.store_var(packed)
	f.close()

func deserialize_level(path: String):
	var SAVE_FILE_PASSWORD := "%SFPWD_V0001%"
	var password := ""
	if SAVE_FILE_PASSWORD[0] != "%" and SAVE_FILE_PASSWORD.right(0) != "%":
		password = SAVE_FILE_PASSWORD
	var f := File.new()
	f.open_encrypted_with_pass(path, File.READ, password)
	var packed: String = f.get_var()
	f.close()
	var package: PackedScene = str2var(packed)
	set_level_defered(package)

func deserialize_level_debug(packed: String):
	var package: PackedScene = str2var(packed)
	set_level_defered(package)

func set_level_defered(level: PackedScene):
	get_tree().change_scene_to(level)
	# var new_level: Node = level.instance()
	# get_tree().root.call_deferred("add_child", new_level)
	# get_tree().set_deferred("current_level", new_level)
	emit_signal("__changing_to_scene", level)
	var tem := template
	while tem == get_tree().current_scene:
		yield(get_tree(), "idle_frame")
	emit_signal("__template_changed")
	if is_instance_valid(tem):
		tem.free()
	template = get_tree().current_scene
	# get_tree().paused = true
	# yield(get_tree(), "idle_frame")
	# # -----------------------------------------------
	# var instanced = level.instance()
	# var old_stuff = template.singletons_pool
	# var new_stuff = instanced.singletons_pool
	# instanced.remove_child(new_stuff)
	# template.call_deferred("remove_child", old_stuff)
	# template.call_deferred("add_child", instanced.singletons_pool)
	# # -----------------------------------------------
	# old_stuff.queue_free()
	# old_stuff = template.peripherals_pool
	# new_stuff = instanced.peripherals_pool
	# instanced.remove_child(new_stuff)
	# template.call_deferred("remove_child", old_stuff)
	# template.call_deferred("add_child", instanced.peripherals_pool)
	# # -----------------------------------------------
	# old_stuff.queue_free()
	# old_stuff = template.scenes_holder
	# new_stuff = instanced.scenes_holder
	# instanced.remove_child(new_stuff)
	# template.call_deferred("remove_child", old_stuff)
	# template.call_deferred("add_child", instanced.scenes_holder)
	# # -----------------------------------------------
	# old_stuff.queue_free()
	# old_stuff = template.unpaused_pool
	# new_stuff = instanced.unpaused_pool
	# instanced.remove_child(new_stuff)
	# template.call_deferred("remove_child", old_stuff)
	# template.call_deferred("add_child", instanced.unpaused_pool)
	# # -----------------------------------------------
	# instanced.queue_free()
	# get_tree().paused = false

# func set_level_defered_debug(level: PackedScene):
# 	var instanced: Node = level.instance()
# 	var old_holder := template.scenes_holder
# 	template.call_deferred("remove_child", old_holder)
# 	template.call_deferred("add_child", instanced)
# 	old_holder.queue_free()

func load_level(cfg: LevelConfiguration, wait := false, no_temp := false) -> bool:
	if no_temp:
		setup_template()
		yield(get_tree(), "idle_frame")
	while curr_lmac != null:
		if wait:
			yield(get_tree(), "idle_frame")
		else:
			Out.print_warning("A different level is currently being loaded", \
				get_stack())
			return false
	level_change_cleanup()
	curr_lmac = LM_AssistClass.new(get_tree())
	curr_lmac.connect("__lmac_finished", self, "lmac_finish_handler")
	curr_lmac.connect("__change_next_frame", self, "lmac_change_next_frame_handler")
	curr_lmac.setup_autoloads(cfg.singletons_list)
	curr_lmac.spawn_loading_scene(cfg.loading_scene_path)
	curr_lmac.load_main(cfg.scene_path, cfg.preload_list)

	return true

func setup_template():
	var curr_main := get_tree().current_scene
	get_tree().change_scene_to(LEVEL_TEMPLATE_SOURCE)
	curr_main.queue_free()
	emit_signal("__template_changed")

func level_change_cleanup():
	if oneshot_singletons.empty():
		return
	SingletonManager.remove_multiple(oneshot_singletons)

func change_template(to: PackedScene):
	var curr_main := get_tree().current_scene
	get_tree().change_scene_to(to)
	curr_main.queue_free()
	emit_signal("__template_changed")

func template_change_handler():
	yield(get_tree(), "idle_frame")
	get_template(true)
	IRM.local_irm = template.local_irm
	SingletonManager.local_singletons_swarm = template.singletons_pool

func lmac_finish_handler():
	curr_lmac.disconnect("__lmac_finished", self, "lmac_finish_handler")
	curr_lmac.disconnect("__change_next_frame", self, "lmac_change_next_frame_handler")
	curr_lmac = null

func lmac_change_next_frame_handler(to):
	emit_signal("__changing_to_scene", to)
