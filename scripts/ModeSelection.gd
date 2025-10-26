class_name ModeSelection
extends Control

var background: TextureRect
var title_label: Label
var modes_list: VBoxContainer
var back_button: Button
var copyright_label: Label

@export var mode_selection_panel_color: Color = Color(0.98, 0.97, 0.94, 0.95)

# Флаг инициализации
var _is_initialized: bool = false

func _ready():
	if _is_initialized:
		return
	
	find_nodes()
	setup_ui()
	update_localization()
	
	_is_initialized = true

func find_nodes():
	background = get_node_or_null("Background")
	title_label = get_node_or_null("VBox/TitleLabel")
	modes_list = get_node_or_null("VBox/ScrollContainer/ModesList")
	back_button = get_node_or_null("VBox/BackButton")
	copyright_label = get_node_or_null("CopyrightLabel")

func setup_ui():
	# Подключаем статичные кнопки из сцены
	connect_mode_buttons()
	
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	# Применяем тему
	apply_theme()
	
	# Фон
	if background and AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if bg_texture:
			background.texture = bg_texture

func connect_mode_buttons():
	var classic_button = get_node_or_null("VBox/ScrollContainer/ModesList/ClassicButton")
	var time_attack_button = get_node_or_null("VBox/ScrollContainer/ModesList/TimeAttackButton")
	var survival_button = get_node_or_null("VBox/ScrollContainer/ModesList/SurvivalButton")
	
	if classic_button and not classic_button.pressed.is_connected(_on_mode_selected):
		classic_button.pressed.connect(_on_mode_selected.bind(GameModeManager.GameMode.CLASSIC))
	
	if time_attack_button and not time_attack_button.pressed.is_connected(_on_mode_selected):
		time_attack_button.pressed.connect(_on_mode_selected.bind(GameModeManager.GameMode.TIME_ATTACK))
	
	if survival_button and not survival_button.pressed.is_connected(_on_mode_selected):
		survival_button.pressed.connect(_on_mode_selected.bind(GameModeManager.GameMode.SURVIVAL))

func apply_theme():
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	add_theme_stylebox_override("panel", main_style)
	
	# Адаптивные размеры
	var viewport_size = get_viewport().get_visible_rect().size
	var base_font_size = viewport_size.x * 0.025
	base_font_size = clamp(base_font_size, 18, 48)
	
	# Title
	if title_label:
		var title_size = int(base_font_size * 2.0)
		title_size = clamp(title_size, 36, 64)
		title_label.add_theme_font_size_override("font_size", title_size)
		title_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))
	
	# Back button
	if back_button:
		var button_size = int(base_font_size * 1.5)
		button_size = clamp(button_size, 24, 48)
		back_button.add_theme_font_size_override("font_size", button_size)
	
	# Обновляем размеры кнопок режимов
	update_mode_button_sizes()

func update_mode_button_sizes():
	var classic_button = get_node_or_null("VBox/ScrollContainer/ModesList/ClassicButton")
	var time_attack_button = get_node_or_null("VBox/ScrollContainer/ModesList/TimeAttackButton")
	var survival_button = get_node_or_null("VBox/ScrollContainer/ModesList/SurvivalButton")
	
	var viewport_size = get_viewport().get_visible_rect().size
	var base_font_size = viewport_size.x * 0.025
	base_font_size = clamp(base_font_size, 18, 42)
	
	var button_font_size = int(base_font_size * 1.5)
	button_font_size = clamp(button_font_size, 24, 48)
	
	var button_height = viewport_size.y * 0.1
	button_height = clamp(button_height, 60, 100)
	
	for button in [classic_button, time_attack_button, survival_button]:
		if button:
			button.add_theme_font_size_override("font_size", button_font_size)
			button.custom_minimum_size.y = button_height

func update_localization():
	if not LocalizationManager:
		return
	
	# Title
	if title_label:
		title_label.text = LocalizationManager.get_text("mode_selection")
	
	# Mode buttons
	var classic_button = get_node_or_null("VBox/ScrollContainer/ModesList/ClassicButton")
	var time_attack_button = get_node_or_null("VBox/ScrollContainer/ModesList/TimeAttackButton")
	var survival_button = get_node_or_null("VBox/ScrollContainer/ModesList/SurvivalButton")
	
	if classic_button:
		classic_button.text = GameModeManager.get_mode_name(GameModeManager.GameMode.CLASSIC)
	if time_attack_button:
		time_attack_button.text = GameModeManager.get_mode_name(GameModeManager.GameMode.TIME_ATTACK)
	if survival_button:
		survival_button.text = GameModeManager.get_mode_name(GameModeManager.GameMode.SURVIVAL)
	
	# Back button
	if back_button:
		back_button.text = LocalizationManager.get_text("menu")
	
	# Copyright
	update_copyright_text()

func update_copyright_text():
	if copyright_label and LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "© 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "© 2025 13.ink - All rights reserved"

func _on_mode_selected(mode: int):
	print("Mode selected: ", GameModeManager.get_mode_name(mode))
	GameModeManager.set_game_mode(mode)
	GameModeManager.save_selected_mode()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_back_pressed():
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# Обновляем размеры при изменении окна
		call_deferred("apply_theme")
