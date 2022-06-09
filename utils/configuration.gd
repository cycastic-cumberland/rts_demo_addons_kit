extends Resource

class_name Configuration

var name := "Configuration"
var property_list: PoolStringArray = []
var exclusion_list: PoolStringArray =\
	["name", "property_list", "exclusion_list"]

func _init():
	property_list = cleanse_property_list(get_property_list())

func _integrity_check() -> bool:
	return true

func __is_config():
	return true

func cleanse_property_list(list: Array) -> PoolStringArray:
	var new_list: PoolStringArray= []
	var clear := false
	for content in list:
		var prop: Dictionary = content
		
		if prop["name"] in exclusion_list:
			continue
		if clear:
			new_list.push_back(prop["name"])
			continue
		if prop["name"] == "Script Variables":
			clear = true
	return new_list

func try_instance_config(path: String):
	if not ResourceLoader.exists(path):
		return null
	var script: Script = load(path)
	var instance := Resource.new()
	instance.set_script(script)
	return instance

func dictionary_handler(dict: Dictionary):
	if dict.has("__config_class_path"):
		var subres_script_path: String = dict["__config_class_path"]
		var new_subres = try_instance_config(subres_script_path)
		if new_subres != null:
			new_subres._import(dict)
			return new_subres
		else:
			push_error("Can't instance script with path: " + subres_script_path)
			return null
	else:
		return dict

func copy(from: Configuration) -> bool:
	var full_completion := true
	for component in property_list:
		if not component in from:
			push_warning("Warning: failed to copy property: " + component)
			full_completion = false
			continue
		set(component, from.get(component))
	return full_completion and _integrity_check()

func _import(config: Dictionary) -> bool:
	var full_completion := true
	for variable in property_list:
		if not config.has(variable):
			push_warning("Warning: failed to import property: " + variable)
			full_completion = false
			continue
		var value = config[variable]
		var cured = value
		if value is Dictionary:
			cured = dictionary_handler(value)
		set(variable, cured)
	return full_completion and _integrity_check()

func _export(replace_subres := true) -> Dictionary:
	var re := {}
	for variable in property_list:
		var component = get(variable)
		if not replace_subres or not component is Reference:
			re[variable] = component
		else:
			if component is Node:
				continue
			elif component.has_method("__is_config"):
				var subres: Dictionary = component._export()
				var script_path: String = component.get_script().resource_path
				subres["__config_class_path"] = script_path
				re[variable] = subres
			else:
				re[variable] = component
	return re

func read_from(path: String, encryption_key := "") -> int:
	var file := File.new()
	var err: int
	if encryption_key.empty():
		err = file.open(path, File.READ)
	else:
		err = file.open_encrypted_with_pass(path, File.READ, encryption_key)
	if err != OK:
		push_error("Error ({ecode}): Can't open file at: {path}"\
			.format({"ecode": err, "path": path}))
	else:
		var dict: Dictionary = file.get_var()
		file.close()
		_import(dict)
	return err

func save_as(path: String, encryption_key := "") -> int:
	var file := File.new()
	var err: int
	if encryption_key.empty():
		err = file.open(path, File.WRITE)
	else:
		err = file.open_encrypted_with_pass(path, File.WRITE, encryption_key)
	if err != OK:
		push_error("Error ({ecode}): Can't open file at: {path}"\
			.format({"ecode": err, "path": path}))
	else:
		var exported := _export()
		file.store_var(exported)
		file.close()
	return err
