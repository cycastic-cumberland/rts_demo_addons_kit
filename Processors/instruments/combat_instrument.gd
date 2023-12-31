extends Processor

class_name CombatInstrument

# Volatile
var green_light := false

func _init():
	
	remove_property("green_light")
	name = "CombatInstrument"
	return self

func _reset_volatile() -> void:
	._reset_volatile()
	green_light = false

func _controller_instrument_changed(controller, new_instrument):
	if new_instrument != self:
		green_light = false
		set_terminated(true)
		# controller.disconnect("__computer_changed", self,\
		# 	"_controller_computer_changed")

func _vessel_defeated_handler(_con):
	set_terminated(true)

func _lock_on_handler(_com, target):
	pass

func _loose_lock_handler(_tar):
	pass
