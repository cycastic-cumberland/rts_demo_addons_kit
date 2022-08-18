extends Configuration

class_name AircraftConfiguration

var acceleration 		:= 1.0
var deccelaration		:= -2.0
var speedSnapping		:= 1.0
var climbRate			:= 1.2
var minThrottle			:= 0.2
var maxThrottle			:= 1.0
var maxSpeed			:= 100.0
var rollAmplifier		:= 10.0
var pitchAmplifier		:= 0.07
var maxRollAngle		:= PI / 4.0
var maxPitchAngle		:= PI / 2.0
var turnRate			:= 0.05
var maxTurnRate			:= 0.05
var slowingAt			:= 0.3
var orbitError			:= 0.01
var deadzone			:= 1.0
var switchDesZonePerc	:= 0.1

# Min/max switchDesZone squared
var minSDZS				:= 625.0
var maxSDZS				:= 10000.0
var slowingTime			:= 0.07
var aerodynamic			:= 0.8
var radarSignature		:= 1.5
var heatSignature		:= 10.0
var weight				:= 10.0
var speedLossMod		:= 15.0
 
func _init():
	
	name = "AircraftConfiguration"
	return self
