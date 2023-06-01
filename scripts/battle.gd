extends Control

signal textbox_closed

@export var enemy: Resource = null

var current_player_health: int = 0
var current_enemy_health: int = 0
var current_player_defense: int = 0
var current_enemy_defense: int = 0
var current_player_rage: int = 0

func _ready():
	set_health($EnemyContainer/ProgressBar, enemy.health, enemy.health)
	set_health($PlayerPanel/PlayerData/VBoxContainer/ProgressBar, State.current_health, State.max_health)
	set_rage($PlayerPanel/PlayerData/VBoxContainer/Rage, State.current_rage, State.max_rage)
	$EnemyContainer/Enemy.texture = enemy.texture
	
	current_player_health = State.current_health
	current_enemy_health = enemy.health
	
	current_player_defense = State.defense
	current_enemy_defense = enemy.defense
	
	current_player_rage = State.current_rage
	
	$TextBox.hide()
	$ActionsPanel.hide()
	display_text("A wild %s appears!" % enemy.name)
	await self.textbox_closed
	$ActionsPanel.show()
	
func set_health(progress_bar: Node, health: int, max_health: int):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]
	
func set_rage(progress_bar: Node, rage: int, max_rage: int):
	progress_bar.value = rage
	progress_bar.max_value = max_rage
	progress_bar.get_node("Label").text = "RP: %d/%d" % [rage, max_rage]

func _input(_event):
	if (Input.is_action_just_pressed("ui_accept") or \
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and \
		($TextBox.visible or $EndScreen.visible):
		$TextBox.hide()
		emit_signal("textbox_closed")
		
		
func display_text(text):
	$ActionsPanel.hide()
	$TextBox.show()
	$TextBox/Label.text = text
	

func enemy_turn():
	var damage_roll = calc_hit_damage(State.defense, enemy.damage)
	if damage_roll.damage == 0:
		display_text("The %s missed!" % enemy.name)
		await self.textbox_closed	
	elif damage_roll.crit:
		display_text("The %s giga taunts you for %d damage!" % [enemy.name, damage_roll.damage])
		current_player_health = max(0, current_player_health - damage_roll.damage)
		set_health($PlayerPanel/PlayerData/VBoxContainer/ProgressBar, current_player_health, State.max_health)
		$AnimationPlayer.play("player_damaged")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
		current_player_rage = min(10, current_player_rage + 5)
		set_rage($PlayerPanel/PlayerData/VBoxContainer/Rage, current_player_rage, State.max_rage)
	else:
		display_text("The %s taunts you for %d damage!" % [enemy.name, damage_roll.damage])
		current_player_health = max(0, current_player_health - damage_roll.damage)
		set_health($PlayerPanel/PlayerData/VBoxContainer/ProgressBar, current_player_health, State.max_health)
		$AnimationPlayer.play("player_damaged")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
		current_player_rage = min(10, current_player_rage + 5)
		set_rage($PlayerPanel/PlayerData/VBoxContainer/Rage, current_player_rage, State.max_rage)
	if current_player_health == 0:
		display_text("You died. How pathetic...")
		await self.textbox_closed
		await get_tree().create_timer(1).timeout
		$AnimationPlayer.play("game_quit")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
		get_tree().quit()
	$ActionsPanel.show()


func _on_run_pressed():
	display_text("Fled like a bitch")
	await self.textbox_closed
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func _on_attack_pressed():
	var damage_roll = calc_hit_damage(enemy.defense, State.damage)
	if damage_roll.damage == 0:
		display_text("You missed the %s!" % enemy.name)
		await self.textbox_closed	
	elif damage_roll.crit:
		display_text("You giga punch the %s for %d damage!" % [enemy.name, damage_roll.damage])
		current_enemy_health = max(0, current_enemy_health - damage_roll.damage)
		set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)
		$AnimationPlayer.play("enemy_damaged")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
	else:
		display_text("You punch the %s for %d damage!" % [enemy.name, damage_roll.damage])
		current_enemy_health = max(0, current_enemy_health - damage_roll.damage)
		set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)
		$AnimationPlayer.play("enemy_damaged")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
	if current_enemy_health == 0:
		display_text("The %s was banished." % enemy.name)
		$AnimationPlayer.play("enemy_died")
		await $AnimationPlayer.animation_finished
		await get_tree().create_timer(1).timeout
		$AnimationPlayer.play("game_quit")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
		get_tree().quit()
	
	enemy_turn()
	
func calc_hit_damage(defense: int, damage: Array, attack_mod: int = 0):
	var attack_roll:int = (randi()%20+1) + attack_mod
	var roll:int = 0
	var crit: bool = false
	if attack_roll == 20:
		crit = true
	if attack_roll >= defense:
		for i in range(0, damage[0] if attack_roll != 20 else damage[0]*2):
			roll += randi()%damage[1]+1
	else:
		roll = 0
	return {"damage": roll, "crit":crit}
	
		


func _on_special_pressed():
	if current_player_rage >= 10:
		current_player_rage -= 10
		set_rage($PlayerPanel/PlayerData/VBoxContainer/Rage, current_player_rage, State.max_rage)
		display_text("You perform VASECTOMY on the %s!" % [enemy.name])
		current_enemy_health = int(current_enemy_health/2) if current_enemy_health > 10 else 0
		set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)
		$AnimationPlayer.play("enemy_damaged")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
	else:
		display_text("You don't have enough rage for that.")
		await self.textbox_closed
	if current_enemy_health == 0:
		display_text("The %s was banished." % enemy.name)
		$AnimationPlayer.play("enemy_died")
		await $AnimationPlayer.animation_finished
		await get_tree().create_timer(1).timeout
		$AnimationPlayer.play("game_quit")
		await $AnimationPlayer.animation_finished
		await self.textbox_closed
		get_tree().quit()

	enemy_turn()
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
