extends Configuration

class_name LevelConfiguration, "icons/level_res_icon.png"

# Persistent
export(String) var scene_path := ""
export(PoolStringArray) var preload_list: PoolStringArray = []
export(String) var loading_scene_path := ""


func _init():
	
	name = "LevelConfiguration"
