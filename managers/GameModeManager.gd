class_name GameModeManager
extends RefCounted

# Game modes enum
enum GameMode {
	CLASSIC,      # Standard 2048 gameplay
	TIME_ATTACK,  # Fast-paced with time limit
	SURVIVAL      # Obstacles and challenges appear over time
}

# Game mode properties
var mode_properties = {
	GameMode.CLASSIC: {
		"name_en": "Classic",
		"name_ru": "Классический",
		"desc_en": "Original 2048 gameplay\nReach 2048 tile to win!",
		"desc_ru": "Оригинальная игра 2048\nДостигните плитки 2048 чтобы победить!",
		"icon": "res://assets/graphics/mode_classic.png",
		"time_limit": 0,  # No time limit
		"spawn_obstacles": false,
		"obstacle_frequency": 0.0,
		"win_condition": 2048,
		"special_rules": {}
	},
	GameMode.TIME_ATTACK: {
		"name_en": "Time Attack",
		"name_ru": "Атака времени", 
		"desc_en": "Reach the highest score\npossible in 3 minutes!",
		"desc_ru": "Наберите максимальный счёт\nза 3 минуты!",
		"icon": "res://assets/graphics/mode_time_attack.png",
		"time_limit": 180,  # 3 minutes in seconds
		"spawn_obstacles": false,
		"obstacle_frequency": 0.0,
		"win_condition": -1,  # No tile win condition, score based
		"special_rules": {
			"bonus_scoring": true,  # Extra points for quick moves
			"tile_spawn_rate": 1.5,  # Faster new tile spawning
			"combo_multiplier": true  # Score multipliers for consecutive moves
		}
	},
	GameMode.SURVIVAL: {
		"name_en": "Survival",
		"name_ru": "Выживание",
		"desc_en": "Survive as long as possible!\nObstacles appear over time.",
		"desc_ru": "Выживайте как можно дольше!\nПрепятствия появляются со временем.",
		"icon": "res://assets/graphics/mode_survival.png", 
		"time_limit": 0,  # No time limit, but challenges increase
		"spawn_obstacles": true,
		"obstacle_frequency": 0.1,  # 10% chance per move after initial period
		"win_condition": -1,  # No specific win condition, survival based
		"special_rules": {
			"obstacle_tiles": true,  # Unmovable obstacle tiles appear
			"increasing_difficulty": true,  # Obstacles become more frequent
			"special_moves_required": false  # May require special moves to clear obstacles
		}
	}
}

# Current game mode
static var current_mode: GameMode = GameMode.CLASSIC

# Mode selection and properties
static func set_game_mode(mode: GameMode):
	current_mode = mode
	print("Game mode set to: ", get_mode_name(mode))

static func get_current_mode() -> GameMode:
	return current_mode

static func get_mode_name(mode: GameMode) -> String:
	var manager = GameModeManager.new()
	var properties = manager.mode_properties[mode]
	
	if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
		return properties["name_ru"]
	else:
		return properties["name_en"]

static func get_mode_description(mode: GameMode) -> String:
	var manager = GameModeManager.new()
	var properties = manager.mode_properties[mode]
	
	if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
		return properties["desc_ru"]
	else:
		return properties["desc_en"]

static func get_mode_properties(mode: GameMode) -> Dictionary:
	var manager = GameModeManager.new()
	return manager.mode_properties[mode]

static func has_time_limit(mode: GameMode = current_mode) -> bool:
	var properties = get_mode_properties(mode)
	return properties["time_limit"] > 0

static func get_time_limit(mode: GameMode = current_mode) -> int:
	var properties = get_mode_properties(mode)
	return properties["time_limit"]

static func spawns_obstacles(mode: GameMode = current_mode) -> bool:
	var properties = get_mode_properties(mode)
	return properties["spawn_obstacles"]

static func get_obstacle_frequency(mode: GameMode = current_mode) -> float:
	var properties = get_mode_properties(mode)
	return properties["obstacle_frequency"]

static func get_win_condition(mode: GameMode = current_mode) -> int:
	var properties = get_mode_properties(mode)
	return properties["win_condition"]

static func get_special_rules(mode: GameMode = current_mode) -> Dictionary:
	var properties = get_mode_properties(mode)
	return properties["special_rules"]

static func has_special_rule(rule: String, mode: GameMode = current_mode) -> bool:
	var special_rules = get_special_rules(mode)
	return special_rules.has(rule) and special_rules[rule]

# Available modes list
static func get_available_modes() -> Array[GameMode]:
	return [GameMode.CLASSIC, GameMode.TIME_ATTACK, GameMode.SURVIVAL]

# Mode validation
static func is_valid_mode(mode: GameMode) -> bool:
	return mode in get_available_modes()

# Save/Load current mode
static func save_selected_mode():
	var config = ConfigFile.new()
	config.set_value("game", "selected_mode", current_mode)
	config.save("user://game_mode.cfg")

static func load_selected_mode():
	var config = ConfigFile.new()
	var err = config.load("user://game_mode.cfg")
	
	if err == OK:
		var saved_mode = config.get_value("game", "selected_mode", GameMode.CLASSIC)
		if is_valid_mode(saved_mode):
			current_mode = saved_mode
		else:
			current_mode = GameMode.CLASSIC
	else:
		current_mode = GameMode.CLASSIC
	
	print("Loaded game mode: ", get_mode_name(current_mode))
