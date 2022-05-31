extends HomingGuidance

class_name ForwardLookingGuidance

const DEFAULT_SEEKING_ANGLE = deg2rad(30.0)

var heat_threshold := 10.0
var seeking_angle := DEFAULT_SEEKING_ANGLE

func _guide(delta: float):
	if not is_instance_valid(target):
		dumb_control()
		self_destruct_handler(delta)
		return
	var fwd_vec: Vector3 = -vtol.global_transform.basis.z
	var target_vec: Vector3 = vtol.global_transform.origin\
		.direction_to(target.global_transform.origin)
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	var angle := fwd_vec.angle_to(target_vec)
	if angle <= seeking_angle\
			and distance_squared <= active_range_squared:
		if vtol.trackingTarget != target:
			vtol._setTracker(target)
			manual_control = false
	elif distance_squared < detonation_distance_squared and _armed:
		_finalize()
		return
	else:
		dumb_control() 
	self_destruct_handler(delta)
