extends CharacterBody2D

@export var inventory_data: InventoryData
@export var speed: int = 300.0
@onready var interact_ray = $Camera2D/InteractRay
@export var equip_inventory_data: InventoryDataEquip


@export var health: int = 5

var facing_direction: Vector2
signal toggle_inventory


func _ready() -> void:
	PlayerManager.player = self
	
func _physics_process(delta):
	get_input()
	if velocity != Vector2.ZERO	:
		facing_direction = velocity
		interact_ray.global_rotation_degrees = rad_to_deg(facing_direction.angle()) - 90
	move_and_slide()
	
func get_input() -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	if Input.is_action_just_pressed("use"):
		interact()

func _unhandled_input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_pressed("inventory"):
		toggle_inventory.emit()
	

func interact() -> void:
	if interact_ray.is_colliding():
		interact_ray.get_collider().player_interact()

func heal(heal_value: int) -> void:
	health += heal_value
	$Label.text = "Hmm\ncoffee"
	$Label.show()
	await get_tree().create_timer(1).timeout
	$Label.text = ""
	$Label.hide()
