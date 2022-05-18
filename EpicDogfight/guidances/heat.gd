extends HomingGuidance

class_name HeatSeekingGuidance

const DEFAULT_SEEKING_ANGLE = deg2rad(30.0)

var heat_threshold := 10.0
var seeking_angle := DEFAULT_SEEKING_ANGLE

func _guide(delta: float):
	var fwd_vec: Vector3 = -vtol.global_transform.basis.z
	var target_vec: Vector3 = vtol.global_transform.origin\
		.direction_to(target.global_transform.origin)
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	if fwd_vec.angle_to(target_vec) <= seeking_angle\
			and distance_squared <= active_range_squared:
		if distance_squared < detonation_distance_squared:
			_finalize()
			_clean()
			return
		elif vtol.trackingTarget != target:
			vtol._setTracker(target)
#		self_destruct_clock = 0.0
		manual_control = false
	else:
		dumb_control() 
	self_destruct_handler(delta)
