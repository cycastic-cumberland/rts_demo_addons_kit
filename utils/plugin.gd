tool
extends EditorPlugin

func _enter_tree():
	if not Engine.editor_hint:
		return
	# add_custom_type(
	# 	"LineDrawer",
	# 	"ImmediateGeometry",
	# 	preload("line_drawer.gd"),
	# 	null
	# )
	# add_custom_type(
	# 	"SimpleSpatialLOD",
	# 	"Spatial",
	# 	preload("lod.gd"),
	# 	null
	# )
	# add_autoload_singleton(
	# 	"SingletonManager",
	# 	"res://addons/utils/singletons/singleton_manager.gd"
	# )
	# add_autoload_singleton(
	# 	"Out",
	# 	"res://addons/utils/singletons/error_handler.gd"
	# )
	# add_autoload_singleton(
	# 	"IRM",
	# 	"res://addons/utils/singletons/inref_manager.gd"
	# )
	# add_autoload_singleton(
	# 	"GDS_Scheduler",
	# 	"res://addons/utils/singletons/gds_scheduler.gd"
	# )

func _exit_tree():
	if not Engine.editor_hint:
		return
	# remove_custom_type("LineDrawer")
	# remove_custom_type("SimpleSpatialLOD")
	# remove_autoload_singleton("SingletonManager")
	# remove_autoload_singleton("Out")
	# remove_autoload_singleton("IRM")
	# remove_autoload_singleton("GDS_Scheduler")
