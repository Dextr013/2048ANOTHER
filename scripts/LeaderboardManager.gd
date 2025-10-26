extends Node

# Упрощенный менеджер таблицы лидеров для Poki
# Poki не предоставляет API для таблиц лидеров, используем локальное хранение

signal leaderboard_loaded(entries: Array)
signal score_saved(success: bool)

var _is_initialized: bool = true  # Всегда инициализирован для Poki
var _local_cache: Array = []
var _player_best_score: int = 0

const LOCAL_SAVE_PATH = "user://leaderboard.save"
const MAX_LOCAL_ENTRIES = 100

func _ready():
	print("=== LeaderboardManager Initializing ===")
	load_local_cache()
	_is_initialized = true

func is_initialized() -> bool:
	return _is_initialized

func save_score(score: int, highest_tile: int = 0):
	"""Сохранение счета в локальную таблицу лидеров"""
	if score <= 0:
		print("LeaderboardManager: Invalid score, not saving")
		return
	
	# Обновляем локальный лучший счет
	if score > _player_best_score:
		_player_best_score = score
	
	# Сохраняем локально
	save_to_local_cache(score, highest_tile)
	score_saved.emit(true)
	
	print("LeaderboardManager: Score saved locally: ", score)

func load_leaderboard(_include_user: bool = true, _quantity: int = 10):
	"""Загрузка локальной таблицы лидеров"""
	print("LeaderboardManager: Loading local leaderboard")
	leaderboard_loaded.emit(_local_cache)

func save_to_local_cache(score: int, highest_tile: int):
	"""Сохранение в локальный кэш"""
	var entry = {
		"player_name": "You",
		"score": score,
		"highest_tile": highest_tile,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Добавляем новую запись
	_local_cache.append(entry)
	
	# Сортируем по счету
	_local_cache.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Ограничиваем размер
	if _local_cache.size() > MAX_LOCAL_ENTRIES:
		_local_cache.resize(MAX_LOCAL_ENTRIES)
	
	save_local_cache()

func save_local_cache():
	"""Сохранение кэша на диск"""
	var file = FileAccess.open(LOCAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"entries": _local_cache,
			"player_best": _player_best_score
		}
		file.store_var(data)
		file.close()
		print("LeaderboardManager: Local cache saved")

func load_local_cache():
	"""Загрузка кэша с диска"""
	if not FileAccess.file_exists(LOCAL_SAVE_PATH):
		print("LeaderboardManager: No local cache found")
		return
	
	var file = FileAccess.open(LOCAL_SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		
		if data and typeof(data) == TYPE_DICTIONARY:
			_local_cache = data.get("entries", [])
			_player_best_score = data.get("player_best", 0)
			print("LeaderboardManager: Loaded ", _local_cache.size(), " entries from cache")

func get_local_leaderboard() -> Array:
	"""Получение локальной таблицы"""
	return _local_cache.duplicate()

func clear_local_cache():
	"""Очистка локального кэша"""
	_local_cache.clear()
	_player_best_score = 0
	save_local_cache()

func get_player_best_score() -> int:
	return _player_best_score
