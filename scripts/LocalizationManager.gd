extends Node

enum Language {
	ENGLISH,
	RUSSIAN
}

var current_language: Language = Language.ENGLISH

# ЕДИНОЕ НАЗВАНИЕ ИГРЫ
const GAME_TITLE_EN = "Cyberpunk 2048"
const GAME_TITLE_RU = "Киберпанк 2048"

var translations = {
	Language.ENGLISH: {
		# Основное
		"title": GAME_TITLE_EN,
		"game_name": GAME_TITLE_EN,
		
		# Меню
		"play": "PLAY",
		"continue": "CONTINUE",
		"settings": "SETTINGS",
		"achievements": "ACHIEVEMENTS",
		"leaderboard": "LEADERBOARD",
		"credits": "CREDITS",
		"quit": "QUIT",
		"menu": "MENU",
		"restart": "RESTART",
		"how_to_play": "HOW TO PLAY",
		
		# Игра
		"score_display": "SCORE",
		"best_display": "BEST",
		"game_over": "GAME OVER",
		"you_win": "YOU WIN!",
		"time": "Time",
		"time_remaining": "Time Remaining",
		"obstacles": "Obstacles",
		
		# Рекламный
		"watch_ad": "WATCH AD",
		"watch_ad_to_continue": "Watch ad to continue?",
		
		# Настройки
		"language": "Language",
		"background": "Background",
		"music_track": "Music Track",
		"master_volume": "Master Volume",
		"music_volume": "Music Volume",
		"sound_effects": "Sound Effects",
		"previous": "PREV",
		"next": "NEXT",
		"close": "CLOSE",
		
		# Достижения
		"unlocked": "UNLOCKED",
		"locked": "LOCKED",
		"achievement_unlocked": "Achievement Unlocked!",
		
		# Режимы игры
		"classic_mode": "Classic",
		"time_attack_mode": "Time Attack",
		"survival_mode": "Survival",
		"mode_selection": "SELECT MODE",  # ИСПРАВЛЕН КЛЮЧ
		
		# Таблица лидеров
		"rank": "Rank",
		"player": "Player",
		"score": "Score",
		"highest_tile": "Highest Tile",
		"no_scores": "No scores yet. Be the first!",
		
		# Общее
		"loading": "Loading...",
		"saving": "Saving...",
		"error": "Error",
		"ok": "OK",
		"cancel": "CANCEL",
		"yes": "YES",
		"no": "NO"
	},
	
	Language.RUSSIAN: {
		# Основное
		"title": GAME_TITLE_RU,
		"game_name": GAME_TITLE_RU,
		
		# Меню
		"play": "ИГРАТЬ",
		"continue": "ПРОДОЛЖИТЬ",
		"settings": "НАСТРОЙКИ",
		"achievements": "ДОСТИЖЕНИЯ",
		"leaderboard": "ТАБЛИЦА ЛИДЕРОВ",
		"credits": "АВТОРЫ",
		"quit": "ВЫХОД",
		"menu": "МЕНЮ",
		"restart": "ЗАНОВО",
		"how_to_play": "КАК ИГРАТЬ",
		
		# Игра
		"score_display": "СЧЁТ",
		"best_display": "ЛУЧШИЙ",
		"game_over": "ИГРА ОКОНЧЕНА",
		"you_win": "ПОБЕДА!",
		"time": "Время",
		"time_remaining": "Осталось времени",
		"obstacles": "Препятствия",
		
		# Рекламный
		"watch_ad": "ПОСМОТРЕТЬ РЕКЛАМУ",
		"watch_ad_to_continue": "Посмотреть рекламу, чтобы продолжить?",
		
		# Настройки
		"language": "Язык",
		"background": "Фон",
		"music_track": "Музыкальный трек",
		"master_volume": "Общая громкость",
		"music_volume": "Громкость музыки",
		"sound_effects": "Звуковые эффекты",
		"previous": "ПРЕД",
		"next": "СЛЕД",
		"close": "ЗАКРЫТЬ",
		
		# Достижения
		"unlocked": "ОТКРЫТО",
		"locked": "ЗАБЛОКИРОВАНО",
		"achievement_unlocked": "Достижение разблокировано!",
		
		# Режимы игры
		"classic_mode": "Классический",
		"time_attack_mode": "Атака времени",
		"survival_mode": "Выживание",
		"mode_selection": "ВЫБОР РЕЖИМА",  # ИСПРАВЛЕН КЛЮЧ
		
		# Таблица лидеров
		"rank": "Место",
		"player": "Игрок",
		"score": "Счёт",
		"highest_tile": "Максимальная плитка",
		"no_scores": "Ещё нет результатов. Будьте первым!",
		
		# Общее
		"loading": "Загрузка...",
		"saving": "Сохранение...",
		"error": "Ошибка",
		"ok": "ОК",
		"cancel": "ОТМЕНА",
		"yes": "ДА",
		"no": "НЕТ"
	}
}

func _ready():
	print("LocalizationManager initialized")
	load_language()

func get_text(key: String) -> String:
	if translations[current_language].has(key):
		return translations[current_language][key]
	
	# Fallback на английский
	if translations[Language.ENGLISH].has(key):
		print("Warning: Translation missing for '", key, "' in ", get_language_name(current_language))
		return translations[Language.ENGLISH][key]
	
	print("Error: Translation key '", key, "' not found")
	return key.to_upper()

func set_language(lang: Language):
	current_language = lang
	save_language()
	print("Language changed to: ", get_language_name(lang))

func get_current_language() -> Language:
	return current_language

func get_available_languages() -> Array[Language]:
	return [Language.ENGLISH, Language.RUSSIAN]

func get_language_name(lang: Language) -> String:
	match lang:
		Language.ENGLISH:
			return "English"
		Language.RUSSIAN:
			return "Русский"
		_:
			return "Unknown"

func get_game_title() -> String:
	"""Возвращает название игры на текущем языке"""
	match current_language:
		Language.RUSSIAN:
			return GAME_TITLE_RU
		_:
			return GAME_TITLE_EN

func save_language():
	var config = ConfigFile.new()
	config.set_value("localization", "language", current_language)
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Error saving language settings: ", err)

func load_language():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var saved_lang = config.get_value("localization", "language", Language.ENGLISH)
		if saved_lang in [Language.ENGLISH, Language.RUSSIAN]:
			current_language = saved_lang
			print("Loaded language: ", get_language_name(current_language))
		else:
			print("Invalid saved language, using English")
			current_language = Language.ENGLISH
	else:
		# Определяем язык по системе
		var system_locale = OS.get_locale()
		print("System locale: ", system_locale)
		
		if system_locale.begins_with("ru"):
			current_language = Language.RUSSIAN
			print("Detected Russian system locale")
		else:
			current_language = Language.ENGLISH
			print("Using English as default")
		
		save_language()
