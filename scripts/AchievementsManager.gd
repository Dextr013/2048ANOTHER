# AchievementsManager.gd
class_name AchievementsManager
extends Node

# Achievement definitions
enum AchievementType {
	FIRST_MOVE,
	REACH_64,
	REACH_128, 
	REACH_256,
	REACH_512,
	REACH_1024,
	REACH_2048,
	SCORE_1000,
	SCORE_5000,
	SCORE_10000,
	GAMES_PLAYED_10,
	GAMES_PLAYED_50
}

var achievements = {
	AchievementType.FIRST_MOVE: {
		"name_en": "First Step",
		"name_ru": "Первый шаг",
		"description_en": "Make your first move",
		"description_ru": "Сделайте первый ход",
		"unlocked": false
	},
	AchievementType.REACH_64: {
		"name_en": "Getting Warmed Up",
		"name_ru": "Разогрев",
		"description_en": "Reach the 64 tile",
		"description_ru": "Достигните плитки 64", 
		"unlocked": false
	},
	AchievementType.REACH_128: {
		"name_en": "Nice Progress",
		"name_ru": "Хороший прогресс",
		"description_en": "Reach the 128 tile",
		"description_ru": "Достигните плитки 128",
		"unlocked": false
	},
	AchievementType.REACH_256: {
		"name_en": "Getting Serious", 
		"name_ru": "Становится серьезно",
		"description_en": "Reach the 256 tile",
		"description_ru": "Достигните плитки 256",
		"unlocked": false
	},
	AchievementType.REACH_512: {
		"name_en": "Halfway There",
		"name_ru": "На полпути",
		"description_en": "Reach the 512 tile",
		"description_ru": "Достигните плитки 512",
		"unlocked": false
	},
	AchievementType.REACH_1024: {
		"name_en": "Almost There",
		"name_ru": "Почти готово", 
		"description_en": "Reach the 1024 tile",
		"description_ru": "Достигните плитки 1024",
		"unlocked": false
	},
	AchievementType.REACH_2048: {
		"name_en": "Victory",
		"name_ru": "Победа",
		"description_en": "Reach the legendary 2048 tile", 
		"description_ru": "Достигните легендарную плитку 2048",
		"unlocked": false
	},
	AchievementType.SCORE_1000: {
		"name_en": "Score Hunter",
		"name_ru": "Охотник за очками",
		"description_en": "Reach 1000 points",
		"description_ru": "Наберите 1000 очков",
		"unlocked": false
	},
	AchievementType.SCORE_5000: {
		"name_en": "Point Master",
		"name_ru": "Мастер очков", 
		"description_en": "Reach 5000 points",
		"description_ru": "Наберите 5000 очков",
		"unlocked": false
	},
	AchievementType.SCORE_10000: {
		"name_en": "Score Legend",
		"name_ru": "Легенда очков",
		"description_en": "Reach 10000 points",
		"description_ru": "Наберите 10000 очков",
		"unlocked": false
	},
	AchievementType.GAMES_PLAYED_10: {
		"name_en": "Dedicated Player",
		"name_ru": "Преданный игрок",
		"description_en": "Play 10 games",
		"description_ru": "Сыграйте 10 игр",
		"unlocked": false
	},
	AchievementType.GAMES_PLAYED_50: {
		"name_en": "Addicted",
		"name_ru": "Зависимый",
		"description_en": "Play 50 games", 
		"description_ru": "Сыграйте 50 игр",
		"unlocked": false
	}
}

# Statistics
var stats = {
	"games_played": 0,
	"highest_tile": 0,
	"best_score": 0,
	"total_score": 0,
	"moves_made": 0
}

signal achievement_unlocked(achievement_type: AchievementType)

func _ready():
	load_achievements()

func check_achievement(type: AchievementType):
	if not achievements[type]["unlocked"]:
		achievements[type]["unlocked"] = true
		achievement_unlocked.emit(type)
		save_achievements()
		return true
	return false

func check_tile_achievement(tile_value: int):
	match tile_value:
		64:
			check_achievement(AchievementType.REACH_64)
		128:
			check_achievement(AchievementType.REACH_128)
		256:
			check_achievement(AchievementType.REACH_256)
		512:
			check_achievement(AchievementType.REACH_512)
		1024:
			check_achievement(AchievementType.REACH_1024)
		2048:
			check_achievement(AchievementType.REACH_2048)

func check_score_achievement(score: int):
	if score >= 1000:
		check_achievement(AchievementType.SCORE_1000)
	if score >= 5000:
		check_achievement(AchievementType.SCORE_5000)
	if score >= 10000:
		check_achievement(AchievementType.SCORE_10000)

func update_stats(games_played: int = -1, highest_tile: int = -1, score: int = -1):
	if games_played >= 0:
		stats["games_played"] = games_played
		if games_played >= 10:
			check_achievement(AchievementType.GAMES_PLAYED_10)
		if games_played >= 50:
			check_achievement(AchievementType.GAMES_PLAYED_50)
	
	if highest_tile > stats["highest_tile"]:
		stats["highest_tile"] = highest_tile
		check_tile_achievement(highest_tile)
	
	if score > stats["best_score"]:
		stats["best_score"] = score
		check_score_achievement(score)
	
	if score > 0:
		stats["total_score"] += score
		check_score_achievement(stats["best_score"])
	
	save_achievements()

func get_achievement_name(type: AchievementType) -> String:
	var lang_suffix = "_ru" if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN else "_en"
	return achievements[type]["name" + lang_suffix]

func get_achievement_description(type: AchievementType) -> String:
	var lang_suffix = "_ru" if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN else "_en"
	return achievements[type]["description" + lang_suffix]

func is_achievement_unlocked(type: AchievementType) -> bool:
	return achievements[type]["unlocked"]

func get_unlocked_count() -> int:
	var count = 0
	for achievement in achievements.values():
		if achievement["unlocked"]:
			count += 1
	return count

func get_total_count() -> int:
	return achievements.size()

func save_achievements():
	var save_data = {
		"achievements": achievements,
		"stats": stats
	}
	
	var file = FileAccess.open("user://achievements.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_achievements():
	if not FileAccess.file_exists("user://achievements.save"):
		return
		
	var file = FileAccess.open("user://achievements.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data.has("achievements"):
			achievements = save_data["achievements"]
		if save_data.has("stats"):
			stats = save_data["stats"]
