class_name MainMenu
extends Control

var GameReadyAPI
# УДАЛЕНО: var _on_viewport_size_changed - конфликтующая переменная

# Node references
var title_label: Label
var play_button: Button
var continue_button: Button
var settings_button: Button
var achievements_button: Button
var leaderboard_button: Button
var credits_button: Button
var quit_button: Button
var settings_panel: Panel
var credits_panel: Panel
var background: TextureRect
var copyright_label: Label

# Settings controls
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var background_index_label: Label
var music_index_label: Label

# Inspector-editable panel colors
@export var settings_panel_color: Color = Color(0.1, 0.1, 0.2, 0.9)
@export var credits_panel_color: Color = Color(0.1, 0.1, 0.2, 0.9)

# Флаг инициализации
var _is_initialized: bool = false

func _ready():
	if _is_initialized:
		return
	
	# Даем время на инициализацию всех autoload
	await get_tree().process_frame
	
	# Находим все ноды
	find_all_nodes()
	
	# Создаем недостающие элементы
	create_missing_elements()
	
	# Загружаем настройки менеджеров
	load_managers_settings()
	
	# Настраиваем UI
	setup_ui()
	connect_signals()
	load_settings()
	update_localization()
	update_copyright_text()
	
	# Показываем рекламу с задержкой
	call_deferred("show_interstitial_on_start")
	
	_is_initialized = true

func show_interstitial_on_start():
	# Ждем полной инициализации
	await get_tree().create_timer(2.0).timeout
	
	# Проверяем доступность GameReady через синглтон
	var game_ready = get_game_ready()
	if game_ready:
		if game_ready.has_method("is_ad_available") and game_ready.is_ad_available():
			# Показываем рекламу с вероятностью 30% - ТЕПЕРЬ ДЛЯ POKI
			if randf() < 0.3:
				print("Showing interstitial ad from main menu")
				game_ready.show_interstitial_ad()

func get_game_ready():
	# Пытаемся найти GameReady разными способами
	if has_node("/root/GameReady"):
		return get_node("/root/GameReady")
	
	# Проверяем среди детей корневого узла
	for child in get_tree().root.get_children():
		if child.has_method("is_initialized") and child.has_method("show_interstitial_ad"):
			return child
	
	return null

func find_all_nodes():
	title_label = get_node_or_null("VBox/TitleLabel")
	play_button = get_node_or_null("VBox/ButtonContainer/PlayButton")
	continue_button = get_node_or_null("VBox/ButtonContainer/ContinueButton")
	settings_button = get_node_or_null("VBox/ButtonContainer/SettingsButton")
	achievements_button = get_node_or_null("VBox/ButtonContainer/AchievementsButton")
	leaderboard_button = get_node_or_null("VBox/ButtonContainer/LeaderboardButton")
	credits_button = get_node_or_null("VBox/ButtonContainer/CreditsButton")
	quit_button = get_node_or_null("VBox/ButtonContainer/QuitButton")
	settings_panel = get_node_or_null("SettingsPanel")
	credits_panel = get_node_or_null("CreditsPanel")
	background = get_node_or_null("Background")
	copyright_label = get_node_or_null("CopyrightLabel")

func create_missing_elements():
	var button_container = get_node_or_null("VBox/ButtonContainer")
	if not button_container:
		return
	
	# Создаем недостающие кнопки с правильными настройками
	if not achievements_button:
		achievements_button = Button.new()
		achievements_button.name = "AchievementsButton"
		achievements_button.focus_mode = Control.FOCUS_NONE
		button_container.add_child(achievements_button)
	
	if not leaderboard_button:
		leaderboard_button = Button.new()
		leaderboard_button.name = "LeaderboardButton"
		leaderboard_button.focus_mode = Control.FOCUS_NONE
		button_container.add_child(leaderboard_button)
	
	if not copyright_label:
		copyright_label = Label.new()
		copyright_label.name = "CopyrightLabel"
		add_child(copyright_label)
		copyright_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		copyright_label.position.y -= 30
		copyright_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copyright_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
		copyright_label.add_theme_font_size_override("font_size", 16)

func load_managers_settings():
	# Исправление: используем правильные имена методов
	if LocalizationManager and LocalizationManager.has_method("load_language"):
		LocalizationManager.load_language()
	
	# Если AssetManager существует, загружаем его настройки
	if has_node("/root/AssetManager"):
		var asset_manager = get_node("/root/AssetManager")
		if asset_manager and asset_manager.has_method("load_asset_settings"):
			asset_manager.load_asset_settings()

func setup_ui():
	# Создаем фон
	setup_background()
	
	# Применяем тему
	apply_clean_theme()
	
	# Обновляем фон
	update_background()
	
	# Скрываем панели
	if settings_panel:
		settings_panel.visible = false
	if credits_panel:
		credits_panel.visible = false
	
	# Скрываем кнопку выхода на вебе
	if OS.has_feature("web") and quit_button:
		quit_button.visible = false

func setup_background():
	if not background:
		background = TextureRect.new()
		add_child(background)
		move_child(background, 0)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func apply_clean_theme():
	if background:
		background.modulate = Color.WHITE
	
	# Адаптивные размеры
	var viewport_size = get_viewport().get_visible_rect().size
	var base_font_size = viewport_size.x * 0.025
	base_font_size = clamp(base_font_size, 18, 48)
	
	# Title - ИСПРАВЛЕНО НАЗВАНИЕ
	if title_label:
		var title_size = int(base_font_size * 2.5)
		title_size = clamp(title_size, 40, 80)
		title_label.add_theme_font_size_override("font_size", title_size)
		title_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.text = "Cyberpunk 2048"  # Единое название
	
	# Buttons
	var buttons = [play_button, continue_button, settings_button, achievements_button, 
				   leaderboard_button, credits_button, quit_button]
	
	var button_font_size = int(base_font_size * 1.5)
	button_font_size = clamp(button_font_size, 20, 40)
	
	var button_height = viewport_size.y * 0.08
	button_height = clamp(button_height, 50, 80)
	
	for button in buttons:
		if button:
			button.add_theme_font_size_override("font_size", button_font_size)
			button.custom_minimum_size = Vector2(0, button_height)
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_constant_override("content_margin_left", 20)
			button.add_theme_constant_override("content_margin_right", 20)
			
			# Добавляем стиль для кнопок
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
			button_style.corner_radius_top_left = 8
			button_style.corner_radius_top_right = 8
			button_style.corner_radius_bottom_left = 8
			button_style.corner_radius_bottom_right = 8
			button_style.border_width_left = 2
			button_style.border_width_top = 2
			button_style.border_width_right = 2
			button_style.border_width_bottom = 2
			button_style.border_color = Color(0.8, 0.8, 0.8, 0.5)
			button.add_theme_stylebox_override("normal", button_style)
			
			var hover_style = button_style.duplicate()
			hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
			button.add_theme_stylebox_override("hover", hover_style)

func connect_signals():
	# Подключаем сигналы кнопок
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	
	if continue_button and not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	
	if achievements_button and not achievements_button.pressed.is_connected(_on_achievements_pressed):
		achievements_button.pressed.connect(_on_achievements_pressed)
	
	if leaderboard_button and not leaderboard_button.pressed.is_connected(_on_leaderboard_pressed):
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	
	if credits_button and not credits_button.pressed.is_connected(_on_credits_pressed):
		credits_button.pressed.connect(_on_credits_pressed)
	
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# ИСПРАВЛЕНИЕ: Подключаем сигнал изменения размера окна к методу
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Обновляем видимость кнопки Continue
	update_continue_button_visibility()

# ИСПРАВЛЕНИЕ: Переименован метод для обработки изменения размера viewport
func _on_viewport_resized() -> void:
	"""Обработчик изменения размера окна"""
	print("Viewport size changed - updating UI")
	apply_clean_theme()
	update_copyright_text()
	update_background()

func update_continue_button_visibility():
	if continue_button:
		# Исправление: проверяем существование SaveManager безопасно
		var has_save = false
		if has_node("/root/SaveManager"):
			var save_manager = get_node("/root/SaveManager")
			if save_manager and save_manager.has_method("has_saved_game"):
				has_save = save_manager.has_saved_game()
		
		continue_button.visible = has_save

func _on_play_pressed():
	# Уведомляем Poki о начале игрового процесса
	if has_node("/root/GameReadyAPI"):
		var game_ready = get_node("/root/GameReadyAPI")
		if game_ready and game_ready.has_method("gameplay_start"):
			game_ready.gameplay_start()
	
	get_tree().change_scene_to_file("res://scenes/ModeSelection.tscn")

func _on_continue_pressed():
	# Уведомляем Poki о начале игрового процесса
	if has_node("/root/GameReadyAPI"):
		var game_ready = get_node("/root/GameReadyAPI")
		if game_ready and game_ready.has_method("gameplay_start"):
			game_ready.gameplay_start()
	
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings_pressed():
	if GameReadyAPI and GameReadyAPI.has_method("send_analytics_event"):
		GameReadyAPI.send_analytics_event("menu_settings_clicked")
	
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_achievements_pressed():
	if GameReadyAPI and GameReadyAPI.has_method("send_analytics_event"):
		GameReadyAPI.send_analytics_event("menu_achievements_clicked")
	
	get_tree().change_scene_to_file("res://scenes/Achievements.tscn")

func _on_leaderboard_pressed():
	if GameReadyAPI and GameReadyAPI.has_method("send_analytics_event"):
		GameReadyAPI.send_analytics_event("menu_leaderboard_clicked")
	
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")

func _on_credits_pressed():
	if GameReadyAPI and GameReadyAPI.has_method("send_analytics_event"):
		GameReadyAPI.send_analytics_event("menu_credits_clicked")
	
	show_credits_panel()

func _on_quit_pressed():
	# Эта функция НЕ ДОЛЖНА вызываться на вебе (кнопка скрыта)
	if OS.has_feature("web"):
		return
	
	print("Quit button pressed - exiting game")
	
	# Сохраняем настройки
	save_settings()
	
	# Останавливаем музыку
	if SoundManager:
		SoundManager.stop_music_immediate()
	
	# Используем отложенный выход для безопасности
	call_deferred("safe_quit")

func safe_quit():
	get_tree().quit()

func show_credits_panel():
	if not credits_panel:
		create_credits_panel()
	credits_panel.visible = true

func create_credits_panel():
	credits_panel = Panel.new()
	add_child(credits_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = credits_panel_color
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.0, 1.0, 1.0, 0.6)
	credits_panel.add_theme_stylebox_override("panel", panel_style)
	
	credits_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	credits_panel.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	credits_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	vbox.add_theme_constant_override("separation", 20)
	
	# Title
	var credits_title = Label.new()
	credits_title.text = "CREDITS"
	credits_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_title.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))
	credits_title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(credits_title)
	
	# Content
	var credits_text = Label.new()
	credits_text.text = "13.ink"
	credits_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_text.add_theme_color_override("font_color", Color.WHITE)
	credits_text.add_theme_font_size_override("font_size", 24)
	vbox.add_child(credits_text)
	
	# Close button
	var close_button = Button.new()
	if LocalizationManager:
		close_button.text = LocalizationManager.get_text("close")
	else:
		close_button.text = "CLOSE"
	
	close_button.pressed.connect(_on_credits_close_pressed)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.custom_minimum_size = Vector2(0, 40)
	close_button.focus_mode = Control.FOCUS_NONE
	vbox.add_child(close_button)
	
	credits_panel.visible = false

func _on_credits_close_pressed():
	if credits_panel:
		credits_panel.visible = false

func update_localization():
	if not LocalizationManager:
		return
	
	if title_label:
		title_label.text = LocalizationManager.get_text("title")
	
	if play_button:
		play_button.text = LocalizationManager.get_text("play")
	
	if continue_button:
		continue_button.text = LocalizationManager.get_text("continue")
	
	if settings_button:
		settings_button.text = LocalizationManager.get_text("settings")
	
	if achievements_button:
		achievements_button.text = LocalizationManager.get_text("achievements")
	
	if leaderboard_button:
		leaderboard_button.text = LocalizationManager.get_text("leaderboard")
	
	if credits_button:
		credits_button.text = LocalizationManager.get_text("credits")
	
	if quit_button:
		quit_button.text = LocalizationManager.get_text("quit")
	
	update_copyright_text()

func update_copyright_text():
	if copyright_label and LocalizationManager:
		# ИСПРАВЛЕНИЕ: Заменены символы копирайта на совместимые
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "(C) 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "(C) 2025 13.ink - All rights reserved"
	
	# Обновляем размер шрифта для copyright
	if copyright_label:
		var viewport_size = get_viewport().get_visible_rect().size
		var copyright_size = int(viewport_size.x * 0.015)
		copyright_size = clamp(copyright_size, 12, 20)
		copyright_label.add_theme_font_size_override("font_size", copyright_size)

func update_background():
	if background:
		# ИСПРАВЛЕНИЕ: Добавлена закрывающая кавычка
		var main_menu_bg = load("res://assets/background/Mainmenu.webp")
		if main_menu_bg:
			background.texture = main_menu_bg
		elif has_node("/root/AssetManager"):
			var asset_manager = get_node("/root/AssetManager")
			if asset_manager and asset_manager.has_method("get_current_background"):
				var bg_texture = asset_manager.get_current_background()
				if bg_texture:
					background.texture = bg_texture

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", 0.8)
	config.set_value("audio", "music_volume", 0.4)
	var err = config.save("user://settings.cfg")
	if err != OK:
		print("Error saving settings")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		print("No settings file found, using defaults")

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# На вебе игнорируем
			if OS.has_feature("web"):
				return
			
			# На десктопе - нормальный выход
			save_settings()
			if has_node("/root/SoundManager"):
				var sound_manager = get_node("/root/SoundManager")
				if sound_manager and sound_manager.has_method("stop_music_immediate"):
					sound_manager.stop_music_immediate()
			get_tree().quit()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Пауза при сворачивании приложения
			if SoundManager:
				SoundManager.pause_music()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Возобновление при разворачивании приложения
			if SoundManager:
				SoundManager.resume_music()
