extends Serializable

class_name StateSingular

const STATE_SINGULAR_SIGNALS := {
	"__state_added": "state_machine_pushed_handler",
	"__state_removed": "state_machine_popped_handler"
}

# Persistent
var state_name := ""
var exclusive := false setget set_exclusive
var suspended := false

# Volatile
var current_machine = null
var next_state = null setget , _get_next_state

func _init():
	name = "StateSingular"
	remove_properties(["next_state", "current_machine"])

func set_exclusive(ex: bool):
	exclusive = ex
	# Out.print_debug("Exclusivity set: " + str(ex))

func _get_next_state():
	if not exclusive:
		return next_state
	return null

func blackboard_set(index: String, value):
	if current_machine != null:
		current_machine.blackboard_set(index, value)
	else:
		Out.print_warning("Cannot set blackboard as there is no StateMachine", get_stack())

func blackboard_get(index: String):
	if current_machine != null:
		return current_machine.blackboard_get(index)
	return null

func state_machine_pushed_handler(machine, _name, s_ref):
	if s_ref == self:
		current_machine = machine
		_boot()

func state_machine_popped_handler(machine, _name, s_ref):
	if s_ref == self:
		Utilities.SignalTools.disconnect_from(machine, self, \
			STATE_SINGULAR_SIGNALS)
		_finalize()
		next_state = null
		current_machine = null

func pop():
	Utilities.TrialTools.try_call(current_machine, "remove_state_by_name", \
		[state_name])

func _boot():
	pass

func _compute(delta: float):
	return null

func _finalize():
	pass
