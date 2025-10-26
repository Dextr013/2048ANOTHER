class_name Achievements
extends Control

# Node references
@onready var background: TextureRect = $Background
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var achievements_list: VBoxContainer = $VBoxContainer/ScrollContainer/AchievementsList
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var copyright_label: Label = $CopyrightLabel

# Achievement definitions
var achievements_data = {
	"first_game": {
		"name_en": "First Steps",
		"name_ru": "Первые шаги",
		"desc_en": "Play your first game",
		"desc_ru": "Сыграйте первую игру",
	},
	"reach_128": {
		"name_en": "Getting Started", 
		"name_ru": "Начинающий",
		"desc_en": "Reach the 128 tile",
		"desc_ru": "Достигните плитки 128",
	},
	"reach_256": {
		"name_en": "Building Up",
		"name_ru": "Развитие", 
		"desc_en": "Reach the 256 tile",
		"desc_ru": "Достигните плитки 256",
	},
	"reach_512": {
		"name_en": "Getting Better",
		"name_ru": "Улучшение",
		"desc_en": "Reach the 512 tile", 
		"desc_ru": "Достигните плитки 512",
	},
	"reach_1024": {
		"name_en": "Almost There",
		"name_ru": "Почти цель",
		"desc_en": "Reach the 1024 tile",
		"desc_ru": "Достигните плитки 1024",
	},
	"reach_2048": {
		"name_en": "Victory",
		"name_ru": "Победа",
		"desc_en": "Reach the 2048 tile - You Win",
		"desc_ru": "Достигните плитки 2048 - Победа",
	},
	"efficient_win": {
		"name_en": "Efficiency Expert",
		"name_ru": "Эксперт эффективности",
		"desc_en": "Win the game in under 200 moves",
		"desc_ru": "Выиграйте игру менее чем за 200 ходов",
	},
	"speed_demon": {
		"name_en": "Speed Demon",
		"name_ru": "Демон скорости",
		"desc_en": "Win the game in under 150 moves",
		"desc_ru": "Выиграйте игру менее чем за 150 ходов",
	},
	# Новые достижения для режимов
	"time_master": {
		"name_en": "Time Master",
		"name_ru": "Мастер времени",
		"desc_en": "Complete Time Attack mode",
		"desc_ru": "Пройдите режим Атака времени",
	},
	"fast_thinker": {
		"name_en": "Fast Thinker",
		"name_ru": "Быстрый мыслитель",
		"desc_en": "Complete Time Attack with 30+ seconds remaining",
		"desc_ru": "Пройдите Атаку времени с 30+ секундами в запасе",
	},
	"survivor": {
		"name_en": "Survivor",
		"name_ru": "Выживший",
		"desc_en": "Survive 100 moves in Survival mode",
		"desc_ru": "Выживите 100 ходов в режиме Выживание",
	},
	"obstacle_master": {
		"name_en": "Obstacle Master", 
		"name_ru": "Мастер препятствий",
		"desc_en": "Reach 512 tile with 5+ obstacles in Survival",
		"desc_ru": "Достигните плитки 512 с 5+ препятствиями в Выживании",
	},
	"endurance_champ": {
		"name_en": "Endurance Champion",
		"name_ru": "Чемпион выносливости",
		"desc_en": "Survive 300 moves in Survival mode",
		"desc_ru": "Выживите 300 ходов в режиме Выживание",
	}
}

func _ready():
	# Ensure full screen coverage
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	setup_ui()
	populate_achievements()
	update_localization()

func setup_ui():
	# Connect signals
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("ERROR: Back button not found in Achievements scene!")
	
	# Setup background
	if background and AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if bg_texture:
			background.texture = bg_texture
	
	# Добавляем темный фон для области контента
	add_content_background()

func add_content_background():
	# Создаем темный фон для всей области достижений
	var content_background = ColorRect.new()
	add_child(content_background)
	content_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Темный полупрозрачный цвет для лучшей читаемости
	content_background.color = Color(0.1, 0.1, 0.15, 0.9)
	
	# Перемещаем фон позади всего контента
	move_child(content_background, 1)  # После основного фона, перед всем остальным

func populate_achievements():
	if not achievements_list:
		print("ERROR: achievements_list not found!")
		return
	
	# Clear existing children
	for child in achievements_list.get_children():
		child.queue_free()
	
	# Add separation between achievement items
	achievements_list.add_theme_constant_override("separation", 15)
	
	# Add achievement items
	for achievement_id in achievements_data.keys():
		var achievement_item = create_achievement_item(achievement_id)
		if achievement_item:
			achievements_list.add_child(achievement_item)
	
	# If no achievements were created, show a message
	if achievements_list.get_child_count() == 0:
		var no_achievements_label = Label.new()
		no_achievements_label.text = "No achievements available"
		if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			no_achievements_label.text = "Достижения недоступны"
		no_achievements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_achievements_label.add_theme_font_size_override("font_size", 64)
		no_achievements_label.add_theme_color_override("font_color", Color.WHITE)
		achievements_list.add_child(no_achievements_label)

func create_achievement_item(achievement_id: String) -> Control:
	return create_fallback_achievement_item(achievement_id)

func create_fallback_achievement_item(achievement_id: String) -> Control:
	var achievement_container = HBoxContainer.new()
	
	# Адаптивная высота
	var viewport_size = get_viewport().get_visible_rect().size
	var item_height = viewport_size.y * 0.12
	item_height = clamp(item_height, 80, 140)
	achievement_container.custom_minimum_size = Vector2(0, item_height)
	achievement_container.add_theme_constant_override("separation", 20)
	
	# Фон панели
	var background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_panel.z_index = -1
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	style_box.border_color = Color(0.0, 1.0, 1.0, 0.4)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.content_margin_left = 15
	style_box.content_margin_top = 10
	style_box.content_margin_right = 15
	style_box.content_margin_bottom = 10
	background_panel.add_theme_stylebox_override("panel", style_box)
	
	achievement_container.add_child(background_panel)

	var is_unlocked = false
	if SaveManager and SaveManager.has_method("is_achievement_unlocked"):
		is_unlocked = SaveManager.is_achievement_unlocked(achievement_id)
	
	# Текстовый контейнер
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 8)
	achievement_container.add_child(text_container)
	
	# Адаптивные размеры шрифтов
	# Адаптивные размеры шрифтов
	var base_font_size = viewport_size.x * 0.02
	base_font_size = clamp(base_font_size, 16, 40)
	
	# Название достижения
	var name_label = Label.new()
	var achievement_info = achievements_data[achievement_id]
	
	if LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			name_label.text = achievement_info["name_ru"]
		else:
			name_label.text = achievement_info["name_en"]
	else:
		name_label.text = achievement_info["name_en"]
	
	var name_font_size = int(base_font_size * 1.3)
	name_font_size = clamp(name_font_size, 20, 42)
	name_label.add_theme_font_size_override("font_size", name_font_size)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	text_container.add_child(name_label)
	
# Описание
	var desc_label = Label.new()
	if LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			desc_label.text = achievement_info["desc_ru"]
		else:
			desc_label.text = achievement_info["desc_en"]
	else:
		desc_label.text = achievement_info["desc_en"]
	
	var desc_font_size = int(base_font_size * 1.0)
	desc_font_size = clamp(desc_font_size, 16, 32)
	desc_label.add_theme_font_size_override("font_size", desc_font_size)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_container.add_child(desc_label)
	
# Статус
	var status_label = Label.new()
	if is_unlocked:
		status_label.text = "UNLOCKED"
		if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			status_label.text = "РАЗБЛОКИРОВАНО"
		status_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	else:
		status_label.text = "LOCKED"
		if LocalizationManager and LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			status_label.text = "ЗАБЛОКИРОВАНО"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	
	var status_font_size = int(base_font_size * 1.0)
	status_font_size = clamp(status_font_size, 16, 32)
	status_label.add_theme_font_size_override("font_size", status_font_size)
	achievement_container.add_child(status_label)
	
	return achievement_container

func update_localization():
	if not LocalizationManager:
		return
	
	# Update title
	if title_label:
		title_label.text = LocalizationManager.get_text("achievements")
	
	# Update back button
	if back_button:
		back_button.text = LocalizationManager.get_text("menu")
	
	# Update copyright
	update_copyright_text()
	
	# Update all achievement items
	call_deferred("refresh_achievements")

func refresh_achievements():
	if achievements_list:
		populate_achievements()

func update_copyright_text():
	if copyright_label and LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "© 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "© 2025 13.ink - All rights reserved"

func _on_back_pressed():
	print("Back button pressed in Achievements")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
