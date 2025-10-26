extends Node

signal save_loaded()
signal save_created()
signal save_reset()

var save_data = {
	"current_game": null,
	"highest_score": 0,
	"total_games_played": 0,
	"total_moves": 0,
	"total_play_time": 0.0,
	"achievements": {},
	"settings": {
		"master_volume": 0.8,
		"music_volume": 0.4,
		"language": 0,
		"background_index": 0,
		"music_index": 0
	},
	"statistics": {
		"games_won": 0,
		"games_lost": 0,
		"highest_tile": 0,
		"total_score": 0,
		"average_score": 0.0,
		"best_moves": 999999,
		"total_merges": 0
	}
}

const SAVE_FILE_PATH = "user://save_game.dat"
const BACKUP_FILE_PATH = "user://save_game_backup.dat"

# Кэш для предотвращения частых сохранений
var _save_timer: Timer
var _pending_save: bool = false

func _ready():
	setup_save_timer()
	load_game()

func setup_save_timer():
	# Таймер для батчинга сохранений
	_save_timer = Timer.new()
	add_child(_save_timer)
	_save_timer.wait_time = 2.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_perform_save)

func save_game():
	# Отложенное сохранение для оптимизации
	_pending_save = true
	if not _save_timer.is_stopped():
		_save_timer.start()
	else:
		_save_timer.start()

func _perform_save():
	if not _pending_save:
		return
	
	_pending_save = false
	
	# Создаем резервную копию
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var error = DirAccess.copy_absolute(SAVE_FILE_PATH, BACKUP_FILE_PATH)
		if error != OK:
			print("Warning: Failed to create backup copy: ", error)
	
	# Сохраняем основной файл
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(save_data)
		if json_string:
			save_file.store_string(json_string)
			save_file.close()
			print("Game saved successfully")
			return true
		else:
			print("Error: Failed to stringify save data")
			save_file.close()
			return false
	else:
		print("Error: Failed to open save file for writing")
		return false

func save_game_immediate():
	# Немедленное сохранение для критических моментов
	_pending_save = false
	if _save_timer:
		_save_timer.stop()
	return _perform_save()

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		create_new_save()
		return true
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		if json_text.is_empty():
			print("Save file is empty, creating new save")
			return load_backup()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			if loaded_data is Dictionary:
				merge_save_data(loaded_data)
				save_loaded.emit()
				print("Game loaded successfully")
				return true
			else:
				print("Error: Loaded data is not a dictionary")
				return load_backup()
		else:
			print("Error parsing JSON: ", json.get_error_message(), " at line ", json.get_error_line())
			return load_backup()
	
	print("Error: Failed to open save file")
	return load_backup()

func load_backup():
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		print("No backup file found, creating new save")
		create_new_save()
		return false
	
	print("Attempting to load backup save...")
	var file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		if json_text.is_empty():
			print("Backup file is empty")
			create_new_save()
			return false
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			if loaded_data is Dictionary:
				merge_save_data(loaded_data)
				save_game_immediate()  # Восстанавливаем основной файл
				save_loaded.emit()
				print("Backup save loaded successfully")
				return true
		
		print("Error parsing backup JSON")
	
	create_new_save()
	return false

func merge_save_data(loaded_data: Dictionary):
	# Рекурсивное слияние словарей
	for key in loaded_data:
		if save_data.has(key):
			if save_data[key] is Dictionary and loaded_data[key] is Dictionary:
				merge_dictionaries(save_data[key], loaded_data[key])
			else:
				save_data[key] = loaded_data[key]
		else:
			save_data[key] = loaded_data[key]

func merge_dictionaries(target: Dictionary, source: Dictionary):
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			merge_dictionaries(target[key], source[key])
		else:
			target[key] = source[key]

func create_new_save():
	save_data = {
		"current_game": null,
		"highest_score": 0,
		"total_games_played": 0,
		"total_moves": 0,
		"total_play_time": 0.0,
		"achievements": {},
		"settings": {
			"master_volume": 0.8,
			"music_volume": 0.4,
			"language": 0,
			"background_index": 0,
			"music_index": 0
		},
		"statistics": {
			"games_won": 0,
			"games_lost": 0,
			"highest_tile": 0,
			"total_score": 0,
			"average_score": 0.0,
			"best_moves": 999999,
			"total_merges": 0
		}
	}
	if save_game_immediate():
		save_created.emit()
		print("New save created successfully")

func save_current_game(game_grid: Array, score: int, moves: int):
	save_data["current_game"] = {
		"grid": game_grid.duplicate(true),
		"score": score,
		"moves": moves,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_game()

func has_saved_game() -> bool:
	return save_data["current_game"] != null

func get_saved_game() -> Dictionary:
	if has_saved_game():
		return save_data["current_game"].duplicate(true)
	return {}

func clear_saved_game():
	save_data["current_game"] = null
	save_game()

func update_game_finished(score: int, highest_tile: int, moves: int, won: bool):
	save_data["total_games_played"] += 1
	save_data["total_moves"] += moves
	save_data["statistics"]["total_score"] += score
	
	if score > save_data["highest_score"]:
		save_data["highest_score"] = score
	
	if highest_tile > save_data["statistics"]["highest_tile"]:
		save_data["statistics"]["highest_tile"] = highest_tile
	
	# Обновляем best_moves только если игра выиграна
	if won and moves < save_data["statistics"]["best_moves"]:
		save_data["statistics"]["best_moves"] = moves
	
	if won:
		save_data["statistics"]["games_won"] += 1
	else:
		save_data["statistics"]["games_lost"] += 1
	
	# Обновляем средний счет
	if save_data["total_games_played"] > 0:
		save_data["statistics"]["average_score"] = float(save_data["statistics"]["total_score"]) / float(save_data["total_games_played"])
	
	clear_saved_game()
	save_game_immediate()

func update_play_time(time_delta: float):
	save_data["total_play_time"] += time_delta

func unlock_achievement(achievement_id: String):
	if not save_data["achievements"].has(achievement_id):
		save_data["achievements"][achievement_id] = {
			"unlocked": true,
			"timestamp": Time.get_unix_time_from_system()
		}
		save_game()
		return true
	return false

func is_achievement_unlocked(achievement_id: String) -> bool:
	return save_data["achievements"].has(achievement_id) and save_data["achievements"][achievement_id]["unlocked"]

func get_achievements() -> Dictionary:
	return save_data["achievements"].duplicate(true)

func save_audio_settings(audio_data: Dictionary):
	for key in audio_data:
		if save_data["settings"].has(key):
			save_data["settings"][key] = audio_data[key]
	save_game()

func get_audio_settings() -> Dictionary:
	return {
		"master_volume": save_data["settings"].get("master_volume", 0.8),
		"music_volume": save_data["settings"].get("music_volume", 0.4)
	}

func save_language_setting(language: int):
	save_data["settings"]["language"] = language
	save_game()

func get_language_setting() -> int:
	return save_data["settings"].get("language", 0)

func get_statistics() -> Dictionary:
	return save_data["statistics"].duplicate(true)

func get_total_games_played() -> int:
	return save_data["total_games_played"]

func get_highest_score() -> int:
	return save_data["highest_score"]

func get_highest_tile() -> int:
	"""Добавленный метод для получения самой высокой плитки"""
	return save_data["statistics"]["highest_tile"]

func get_total_play_time() -> float:
	return save_data["total_play_time"]

func get_total_games_won() -> int:
	return save_data["statistics"]["games_won"]

func get_formatted_play_time() -> String:
	var total_seconds = int(save_data["total_play_time"])
	var hours = total_seconds / 3600.0
	var minutes = (total_seconds % 3600) / 60.0
	var seconds = total_seconds % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]

func reset_all_data():
	create_new_save()
	save_reset.emit()
	print("All save data has been reset")

# Получение прогресса игры
func get_game_progress() -> Dictionary:
	return {
		"total_games": get_total_games_played(),
		"games_won": get_total_games_won(),
		"highest_score": get_highest_score(),
		"highest_tile": save_data["statistics"]["highest_tile"],
		"total_play_time": get_formatted_play_time(),
		"achievements_unlocked": save_data["achievements"].size()
	}
