extends CogitoAttribute
class_name CogitoOxygenAttribute

## The rate at which oxygen decays when decaying.
@export var decay_rate : float = 1
## The rate at which oxygen increases when recovering.
@export var recovery_rate : float = 10
## Amount of damage the player gets when player is out of oxygen.
@export var damage_when_zero : float = 6
#time between each damage pulse
@export var damage_pulse_rate : float = 2
@export var regenerate_after : float = 2
@export var auto_regenerate : bool = true

signal is_suffocating()

var is_recovering : bool = false
var player : Node3D
var health_before_suffocation : float = 0
var recovery_timer : Timer
var pulse_damage_timer : Timer


func _ready() -> void:
	value_current = value_start
	player = get_parent()
	
	recovery_timer = Timer.new()
	recovery_timer.wait_time = regenerate_after
	add_child(recovery_timer)
	recovery_timer.timeout.connect(_on_recovery_timer_timeout)
	
	pulse_damage_timer = Timer.new()
	pulse_damage_timer.wait_time = damage_pulse_rate
	add_child(pulse_damage_timer)
	pulse_damage_timer.timeout.connect(_on_pulse_damage_timer_timeout)

#snapshot of current health prior to losing oxygen, the amount of health lost from suffocation, change health damage to pulses,
#use these to have a health regeneration max upon surfacing

func _process(delta):
	if player.is_head_in_water() == true: 
		value_current -= decay_rate * delta
		if value_current <= 0 and pulse_damage_timer.is_stopped():
			CogitoGlobals.debug_log(true, "CogitoOxygenAttribute", "You are suffocating.")
			pulse_damage()
			pulse_damage_timer.start()
			
	if player.is_head_in_water() == false and !is_recovering and recovery_timer.is_stopped() and value_current < value_max:
			recovery_timer.start()
		
	if is_recovering and player.is_head_in_water() == false:
		add(recovery_rate * delta)
		if value_current >= value_max:
			is_recovering = false
		if health_before_suffocation > 0:
			recover_health()
		health_before_suffocation = 0

func on_oxygen_change(_oxygen_name:String, _oxygen_current:float, _oxygen_max:float, has_increased:bool):
	if !has_increased:
		recovery_timer.stop()
		is_recovering = false
		
func _on_recovery_timer_timeout():
	if player.is_head_in_water() == false:
		is_recovering = value_current < value_max
		
func _on_pulse_damage_timer_timeout():
		if value_current <= 0 and player.is_head_in_water() == true:
			player.decrease_attribute("health", damage_when_zero)
			health_before_suffocation += damage_when_zero
			pulse_damage_timer.start()
			
func pulse_damage():
	player.decrease_attribute("health", damage_when_zero)
	health_before_suffocation += damage_when_zero
	
func recover_health():
	for i in range(0, health_before_suffocation):
		player.increase_attribute("health", 1, false) ##a bit choppy and janky but it works, would love to have it be replaced with something smoother
		await get_tree().create_timer(0.2).timeout
