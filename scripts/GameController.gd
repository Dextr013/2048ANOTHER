class_name GameController
extends Control

# Node references
@onready var grid_container: GridContainer = $VBox/GameArea/GridContainer
@onready var score_label: Label = $VBox/UI/ScoreContainer/ScoreLabel
@onready var best_score_label: Label = $VBox/UI/ScoreContainer/BestScoreLabel
@onready var restart_button: Button = $VBox/UI/ButtonContainer/RestartButton
@onready var title_label: Label = $VBox/UI/TitleLabel
@onready var menu_button: Button = $VBox/UI/ButtonContainer/MenuButton
@onready var settings_button: Button = $VBox/UI/ButtonContainer/SettingsButton
@onready var copyright_label: Label = $CopyrightLabel
@onready var how_to_play_button: Button = $VBox/UI/ButtonContainer/HowToPlayButton

# Time Display reference
var time_display
var  VisibilityHandler
# Inspector-editable panel colors
@export_group("Adaptive Settings")
@export var min_tile_size: float = 80.0
@export var max_tile_size: float = 120.0
@export var tile_size_ratio: float = 0.15
@export var grid_spacing_ratio: float = 0.08
@export var min_font_size: int = 14
@export var max_font_size: int = 32

# Game Over Panel
var game_over_panel_scene = preload("res://scenes/ui/game_over_panel.tscn")
var game_over_panel_instance: Control = null

# Mode-specific UI elements
@export var obstacles_label: Label  
@export var mode_info_label: Label

# How to Play Popup
var how_to_play_popup: PopupPanel
var how_to_play_title: Label
var how_to_play_description: Label

# Inspector-editable panel colors
@export var settings_panel_color: Color = Color(0.1, 0.1, 0.2, 0.9)
@export var game_over_panel_color: Color = Color(0.0, 0.0, 0.0, 0.8)
@export var game_won_panel_color: Color = Color(0.0, 0.0, 0.0, 0.8)

# How to Play Popup Settings
@export_group("How to Play Popup Settings")
@export var popup_background_color: Color = Color(0.1, 0.1, 0.2, 0.95)
@export var popup_title_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var popup_description_color: Color = Color(0.8, 0.8, 0.9, 1.0)

# Game state tracking
var moves_count: int = 0
var game_start_time: float = 0.0
var is_loading_saved_game: bool = false

var game_logic: Game2048
var tile_grid: Array = []
var tile_size: float = 80.0
var grid_spacing: float = 8.0
var best_score: int = 0
var is_game_over: bool = false

# Touch input variables
var touch_start_position: Vector2
var min_swipe_distance: float = 30.0

# UI elements created in code
var game_won_panel: Panel
var settings_panel: Panel
var bg_texture_rect: TextureRect

# Timer for time attack mode
var time_attack_timer: Timer

# Game Ready API reference
var game_ready_api = null

# Constants
const GRID_SIZE: int = 4
const SAVE_FILE_PATH: String = "user://best_score.save"

func _ready():
	# Устанавливаем якоря на весь экран
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if VisibilityHandler:
		VisibilityHandler.visibility_changed.connect(_on_visibility_changed)
		print("GameController: Connected to VisibilityHandler")
	
	# Load settings from global managers
	if AssetManager:
		AssetManager.load_asset_settings()
	
	# Get Game Ready API reference
	if has_node("/root/GameReadyAPI"):
		game_ready_api = get_node("/root/GameReadyAPI")
		# Уведомляем Poki о начале игрового процесса
		if game_ready_api and game_ready_api.has_method("gameplay_start"):
			game_ready_api.gameplay_start()
	
	setup_ui()
	setup_game()
	load_best_score()
	
	# Check for saved game and load if needed
	check_for_saved_game()
	
	print("GameController initialized")

func _on_visibility_changed(_is_visible_flag: bool):
	"""Обработка изменения видимости приложения"""
	print("GameController: Visibility changed to ", _is_visible_flag)
	
	if not _is_visible_flag:
		# Приложение свернуто/скрыто - паузим таймеры
		if time_attack_timer and time_attack_timer.is_stopped() == false:
			time_attack_timer.paused = true
			print("GameController: Time attack timer paused")
	else:
		# Приложение активно - возобновляем таймеры
		if time_attack_timer and time_attack_timer.paused:
			time_attack_timer.paused = false
			print("GameController: Time attack timer resumed")

func setup_ui():
	# Create background first
	setup_background()
	
	# Connect button signals
	connect_button_signals()
	
	# Set up the main container
	if grid_container:
		grid_container.columns = GRID_SIZE
	
	# Set up the how to play popup
	setup_how_to_play_popup()
	
	# Set clean theme
	apply_clean_theme()
	
	# Update copyright text
	update_copyright_text()
	
	# Set up adaptive sizing
	setup_adaptive_sizing()
	
	# Ensure TimeDisplay is properly set up
	if time_display:
		time_display.visible = false
	
	print("UI setup complete")

func connect_button_signals():
	# Disconnect first to avoid duplicate connections
	if menu_button:
		if menu_button.is_connected("pressed", _on_menu_pressed):
			menu_button.disconnect("pressed", _on_menu_pressed)
		menu_button.pressed.connect(_on_menu_pressed)
	
	if settings_button:
		if settings_button.is_connected("pressed", _on_settings_pressed):
			settings_button.disconnect("pressed", _on_settings_pressed)
		settings_button.pressed.connect(_on_settings_pressed)
	
	if restart_button:
		if restart_button.is_connected("pressed", _on_restart_pressed):
			restart_button.disconnect("pressed", _on_restart_pressed)
		restart_button.pressed.connect(_on_restart_pressed)
	
	if how_to_play_button:
		if how_to_play_button.is_connected("pressed", _on_how_to_play_pressed):
			how_to_play_button.disconnect("pressed", _on_how_to_play_pressed)
		how_to_play_button.pressed.connect(_on_how_to_play_pressed)

func setup_adaptive_sizing():
	if get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_on_viewport_size_changed")

func setup_how_to_play_popup():
	# Create popup panel
	how_to_play_popup = PopupPanel.new()
	how_to_play_popup.name = "HowToPlayPopup"
	add_child(how_to_play_popup)
	
	# Style the popup
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = popup_background_color
	popup_style.corner_radius_top_left = 16
	popup_style.corner_radius_top_right = 16
	popup_style.corner_radius_bottom_left = 16
	popup_style.corner_radius_bottom_right = 16
	popup_style.border_width_left = 3
	popup_style.border_width_right = 3
	popup_style.border_width_top = 3
	popup_style.border_width_bottom = 3
	popup_style.border_color = Color(0.0, 1.0, 1.0, 0.8)
	how_to_play_popup.add_theme_stylebox_override("panel", popup_style)
	
	# Set initial size
	how_to_play_popup.size = Vector2(600, 500)
	
	# Create container
	var margin_container = MarginContainer.new()
	how_to_play_popup.add_child(margin_container)
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	
	var vbox = VBoxContainer.new()
	margin_container.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	
	# Title
	how_to_play_title = Label.new()
	vbox.add_child(how_to_play_title)
	how_to_play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_to_play_title.add_theme_color_override("font_color", popup_title_color)
	how_to_play_title.add_theme_font_size_override("font_size", 36)
	
	# Description
	how_to_play_description = Label.new()
	vbox.add_child(how_to_play_description)
	how_to_play_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_to_play_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	how_to_play_description.add_theme_color_override("font_color", popup_description_color)
	how_to_play_description.add_theme_font_size_override("font_size", 24)
	how_to_play_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	how_to_play_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	how_to_play_description.clip_text = false
	
	# Close button
	var close_button = Button.new()
	vbox.add_child(close_button)
	if LocalizationManager:
		close_button.text = LocalizationManager.get_text("close")
	else:
		close_button.text = "CLOSE"
	if close_button.is_connected("pressed", _on_how_to_play_close_pressed):
		close_button.disconnect("pressed", _on_how_to_play_close_pressed)
	close_button.pressed.connect(_on_how_to_play_close_pressed)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.custom_minimum_size = Vector2(0, 50)
	close_button.focus_mode = Control.FOCUS_NONE
	
	# Initially hidden
	how_to_play_popup.visible = false

func _on_how_to_play_pressed():
	print("How to Play button pressed")
	
	var current_mode = GameModeManager.get_current_mode()
	var mode_name = GameModeManager.get_mode_name(current_mode)
	var mode_description = GameModeManager.get_mode_description(current_mode)
	
	# Update popup content
	how_to_play_title.text = mode_name
	how_to_play_description.text = mode_description
	
	# Show popup centered
	how_to_play_popup.popup_centered()
	
	print("How to Play Popup shown")

func _on_how_to_play_close_pressed():
	print("How to Play Close button pressed")
	how_to_play_popup.hide()

func setup_background():
	# Create simple background TextureRect
	if not bg_texture_rect:
		bg_texture_rect = TextureRect.new()
		add_child(bg_texture_rect)
		move_child(bg_texture_rect, 0)
		bg_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		
		# Try to load background from AssetManager, fallback to solid color
		if AssetManager:
			var bg_texture = AssetManager.get_current_background()
			if bg_texture:
				bg_texture_rect.texture = bg_texture
			bg_texture_rect.modulate = Color(0.98, 0.97, 0.94, 1.0)
		else:
			bg_texture_rect.modulate = Color(0.98, 0.97, 0.94, 1.0)

func update_copyright_text():
	if copyright_label and LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "© 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "© 2025 13.ink - All rights reserved"

func update_localization():
	# Update all texts based on current language
	if LocalizationManager:
		update_ui_texts()
	else:
		# Fallback to English
		update_ui_texts_fallback()
	
	# Update settings panel if open
	if settings_panel and settings_panel.visible:
		recreate_settings_panel()
	
	# Update game over panel if it exists
	if game_over_panel_instance:
		game_over_panel_instance.update_localization()

func update_ui_texts():
	if restart_button:
		restart_button.text = LocalizationManager.get_text("restart")
	if menu_button:
		menu_button.text = LocalizationManager.get_text("menu")
	if settings_button:
		settings_button.text = LocalizationManager.get_text("settings")
	if title_label:
		title_label.text = LocalizationManager.get_text("title")
	if how_to_play_button:
		how_to_play_button.text = LocalizationManager.get_text("how_to_play")

func update_ui_texts_fallback():
	if restart_button:
		restart_button.text = "RESTART"
	if menu_button:
		menu_button.text = "MENU"
	if settings_button:
		settings_button.text = "SETTINGS"
	if title_label:
		title_label.text = "Cyberpunk 2048"
	if how_to_play_button:
		how_to_play_button.text = "HOW TO PLAY"

func recreate_settings_panel():
	settings_panel.queue_free()
	settings_panel = null
	create_settings_panel()
	settings_panel.visible = true

func apply_clean_theme():
	# Отключаем выделение кнопок
	var buttons = [restart_button, menu_button, settings_button, how_to_play_button]
	for button in buttons:
		if button:
			button.focus_mode = Control.FOCUS_NONE
	
	# Clean, minimal background
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	add_theme_stylebox_override("panel", main_style)
	
	# Title styling
	if title_label:
		if LocalizationManager:
			title_label.text = LocalizationManager.get_text("title")
		else:
			title_label.text = "Cyberpunk 2048"
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Score labels styling
	if score_label:
		score_label.add_theme_font_size_override("font_size", 36)
		score_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))
	
	if best_score_label:
		best_score_label.add_theme_font_size_override("font_size", 36)
		best_score_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))

func setup_game():
	# Get the current selected mode
	var selected_mode = GameModeManager.get_current_mode()
	print("Setting up game with mode: ", GameModeManager.get_mode_name(selected_mode))
	
	game_logic = Game2048.new(selected_mode)
	
	# Connect signals
	connect_game_signals()
	
	# Initialize tile grid
	initialize_tile_grid()
	
	# Setup mode-specific UI
	setup_mode_ui()
	
	# Start time attack timer if needed
	if selected_mode == GameModeManager.GameMode.TIME_ATTACK:
		start_time_attack_timer()
	
	# Initial update
	_on_grid_changed(game_logic.get_grid())
	_on_score_changed(game_logic.get_score())

func connect_game_signals():
	# Disconnect existing connections
	var signals_to_disconnect = {
		"grid_changed": _on_grid_changed,
		"score_changed": _on_score_changed,
		"game_over": _on_game_over,
		"game_won": _on_game_won,
		"obstacles_spawned": _on_obstacles_spawned
	}
	
	for signal_name in signals_to_disconnect:
		var handler = signals_to_disconnect[signal_name]
		if game_logic.is_connected(signal_name, handler):
			game_logic.disconnect(signal_name, handler)
	
	# Connect signals
	game_logic.grid_changed.connect(_on_grid_changed)
	game_logic.score_changed.connect(_on_score_changed)
	game_logic.game_over.connect(_on_game_over)
	game_logic.game_won.connect(_on_game_won)
	game_logic.obstacles_spawned.connect(_on_obstacles_spawned)

func start_time_attack_timer():
	print("Starting Time Attack timer")
	if time_attack_timer:
		time_attack_timer.stop()
		time_attack_timer.queue_free()
	
	time_attack_timer = Timer.new()
	add_child(time_attack_timer)
	time_attack_timer.wait_time = 0.1
	if time_attack_timer.is_connected("timeout", _on_time_attack_tick):
		time_attack_timer.disconnect("timeout", _on_time_attack_tick)
	time_attack_timer.timeout.connect(_on_time_attack_tick)
	time_attack_timer.start()
	
	# Инициализируем время старта игры
	game_start_time = Time.get_ticks_msec() / 1000.0
	if game_logic:
		game_logic.game_start_time = game_start_time
	
	# Инициализируем отображение таймера
	var time_limit = GameModeManager.get_time_limit()
	if time_display and time_display.visible:
		time_display.update_time(time_limit)
	
	print("Time Attack timer started successfully. Time limit: ", time_limit)

func _on_time_attack_tick():
	if not game_logic or game_logic.current_mode != GameModeManager.GameMode.TIME_ATTACK:
		return
	
	if game_logic.game_state != "playing":
		return
	
	# Получаем оставшееся время из game_logic
	var time_left = game_logic.get_time_remaining()
	
	# Обновляем ТОЛЬКО отображение
	if time_display and time_display.visible:
		time_display.update_time(time_left)
	
	# Проверяем окончание времени
	if time_left <= 0:
		game_logic.game_state = "game_over"
		game_logic.emit_signal("game_over")
		if time_attack_timer:
			time_attack_timer.stop()
		print("Time Attack: Time's up!")

func initialize_tile_grid():
	# Clear existing tiles
	if grid_container:
		for child in grid_container.get_children():
			child.queue_free()
	
	tile_grid.clear()
	
	# Create new tile grid
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			var tile = GameTile.new()
			
			# Set grid position
			if tile.has_method("set_grid_position"):
				tile.set_grid_position(Vector2i(i, j))
			else:
				# Alternative: set position via metadata
				tile.set_meta("grid_position", Vector2i(i, j))
			
			# Set adaptive size
			tile.custom_minimum_size = Vector2(tile_size, tile_size)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			if grid_container:
				grid_container.add_child(tile)
			row.append(tile)
		tile_grid.append(row)
	
	print("Tile grid initialized with size: ", tile_size)
	print("Grid spacing: ", grid_spacing)

func _input(event):
	if is_game_over:
		return
	
	# Handle keyboard input
	if event is InputEventKey and event.pressed:
		print("Key pressed: ", event.keycode)
		handle_keyboard_input(event)
	
	# Handle touch/mouse input for swipes
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start_position = event.position
			print("Touch started at: ", event.position)
		else:
			print("Touch ended at: ", event.position)
			handle_swipe(event.position)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				touch_start_position = event.position
				print("Mouse pressed at: ", event.position)
			else:
				print("Mouse released at: ", event.position)
				handle_swipe(event.position)

func handle_keyboard_input(event: InputEventKey):
	match event.keycode:
		KEY_LEFT, KEY_A:
			game_logic.move_left()
		KEY_RIGHT, KEY_D:
			game_logic.move_right()
		KEY_UP, KEY_W:
			game_logic.move_up()
		KEY_DOWN, KEY_S:
			game_logic.move_down()

func handle_swipe(end_position: Vector2):
	var swipe_vector = end_position - touch_start_position
	
	if swipe_vector.length() < min_swipe_distance:
		return
	
	# Determine swipe direction and track moves
	var moved = false
	if abs(swipe_vector.x) > abs(swipe_vector.y):
		# Horizontal swipe
		if swipe_vector.x > 0:
			moved = game_logic.move_right()
		else:
			moved = game_logic.move_left()
	else:
		# Vertical swipe
		if swipe_vector.y > 0:
			moved = game_logic.move_down()
		else:
			moved = game_logic.move_up()
	
	if moved:
		moves_count += 1
		print("Move executed, total moves: ", moves_count)

func _on_grid_changed(grid_data: Array):
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if i < tile_grid.size() and j < tile_grid[i].size():
				# For survival mode obstacles, set instant to true to avoid rotation animation
				var instant = (game_logic.current_mode == GameModeManager.GameMode.SURVIVAL && grid_data[i][j] == -1)
				tile_grid[i][j].set_value(grid_data[i][j], instant)

func _on_score_changed(new_score: int):
	if score_label:
		if LocalizationManager:
			score_label.text = LocalizationManager.get_text("score_display") + " " + str(new_score)
		else:
			score_label.text = "SCORE " + str(new_score)
	
	# Update best score
	if new_score > best_score:
		best_score = new_score
		save_best_score()
		update_best_score_display()

func update_best_score_display():
	if best_score_label:
		if LocalizationManager:
			best_score_label.text = LocalizationManager.get_text("best_display") + " " + str(best_score)
		else:
			best_score_label.text = "BEST " + str(best_score)

func _on_game_over():
	is_game_over = true
	finalize_game_session(false)
	show_game_over_panel()
	
	# Отправка события в Game Ready API
	if game_ready_api and game_ready_api.has_method("send_analytics_event"):
		game_ready_api.send_analytics_event("game_over", {
			"score": game_logic.score,
			"moves": moves_count,
			"mode": GameModeManager.get_mode_name(game_logic.current_mode),
			"highest_tile": get_highest_tile_value()
		})
	
	# Pause music on Game Over
	if SoundManager:
		SoundManager.force_pause_music()
	
	# Stop time attack timer
	if time_attack_timer:
		time_attack_timer.stop()

func _on_game_won():
	finalize_game_session(true)
	show_game_won_panel()
	
	# Отправка события в Game Ready API
	if game_ready_api and game_ready_api.has_method("send_analytics_event"):
		game_ready_api.send_analytics_event("game_won", {
			"score": game_logic.score,
			"moves": moves_count,
			"mode": GameModeManager.get_mode_name(game_logic.current_mode),
			"highest_tile": get_highest_tile_value()
		})
	
	# Stop time attack timer
	if time_attack_timer:
		time_attack_timer.stop()

func show_game_over_panel():
	if not game_over_panel_instance:
		create_game_over_panel()
	game_over_panel_instance.show_panel()

func create_game_over_panel():
	if game_over_panel_instance and is_instance_valid(game_over_panel_instance):
		game_over_panel_instance.queue_free()
	
	game_over_panel_instance = game_over_panel_scene.instantiate()
	add_child(game_over_panel_instance)
	
	# Connect signals
	if game_over_panel_instance.watch_ad_pressed.is_connected(_on_watch_ad_pressed):
		game_over_panel_instance.watch_ad_pressed.disconnect(_on_watch_ad_pressed)
	game_over_panel_instance.watch_ad_pressed.connect(_on_watch_ad_pressed)
	
	if game_over_panel_instance.menu_pressed.is_connected(_on_menu_pressed):
		game_over_panel_instance.menu_pressed.disconnect(_on_menu_pressed)
	game_over_panel_instance.menu_pressed.connect(_on_menu_pressed)
	
	if game_over_panel_instance.restart_pressed.is_connected(_on_restart_pressed):
		game_over_panel_instance.restart_pressed.disconnect(_on_restart_pressed)
	game_over_panel_instance.restart_pressed.connect(_on_restart_pressed)
	
	if game_over_panel_instance.settings_pressed.is_connected(_on_settings_pressed):
		game_over_panel_instance.settings_pressed.disconnect(_on_settings_pressed)
	game_over_panel_instance.settings_pressed.connect(_on_settings_pressed)
	
	# Update localization
	game_over_panel_instance.update_localization()
	
	# Initially hidden
	game_over_panel_instance.hide_panel()

func show_game_won_panel():
	if not game_won_panel:
		create_game_won_panel()
	game_won_panel.visible = true

func create_game_won_panel():
	if game_won_panel and is_instance_valid(game_won_panel):
		game_won_panel.queue_free()
	
	game_won_panel = Panel.new()
	add_child(game_won_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = game_won_panel_color
	game_won_panel.add_theme_stylebox_override("panel", panel_style)
	
	game_won_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_won_panel.size = Vector2(400, 250)
	
	var vbox = VBoxContainer.new()
	game_won_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	
	var title = Label.new()
	title.text = "YOU WIN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	var continue_button = Button.new()
	continue_button.text = "CONTINUE"
	if continue_button.is_connected("pressed", _on_continue_pressed):
		continue_button.disconnect("pressed", _on_continue_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.add_theme_font_size_override("font_size", 24)
	continue_button.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(continue_button)
	
	var play_again_button = Button.new()
	play_again_button.text = "PLAY AGAIN"
	if play_again_button.is_connected("pressed", _on_restart_pressed):
		play_again_button.disconnect("pressed", _on_restart_pressed)
	play_again_button.pressed.connect(_on_restart_pressed)
	play_again_button.add_theme_font_size_override("font_size", 24)
	play_again_button.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(play_again_button)
	
	game_won_panel.visible = false

func _on_restart_pressed():
	print("Restart button pressed")
	is_game_over = false
	game_logic.restart()
	
	if game_over_panel_instance:
		game_over_panel_instance.hide_panel()
	if game_won_panel:
		game_won_panel.visible = false
	
	# Restart time attack timer if needed
	if game_logic.current_mode == GameModeManager.GameMode.TIME_ATTACK:
		start_time_attack_timer()

func _on_continue_pressed():
	if game_won_panel:
		game_won_panel.visible = false

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	print("Viewport size changed to: ", viewport_size)
	
	# Устанавливаем размер основного контейнера на весь экран
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var min_dimension = min(viewport_size.x, viewport_size.y)
	
	# Определяем, мобильное ли устройство
	var is_mobile = OS.has_feature('mobile') or OS.has_feature('android') or OS.has_feature('ios')
	
	# Разные настройки для мобильных и десктоп устройств
	if is_mobile:
		setup_mobile_layout(viewport_size, min_dimension)
	else:
		setup_desktop_layout(viewport_size, min_dimension)

func setup_desktop_layout(viewport_size: Vector2, min_dimension: float):
	print("Setting up desktop layout")
	
	# Стандартные настройки для десктоп
	tile_size = max(min_tile_size, min_dimension * tile_size_ratio)
	tile_size = min(tile_size, max_tile_size)
	grid_spacing = tile_size * grid_spacing_ratio
	
	# Update tile sizes
	update_tile_sizes()
	
	# Adaptive grid spacing
	if grid_container:
		grid_container.add_theme_constant_override("h_separation", int(grid_spacing))
		grid_container.add_theme_constant_override("v_separation", int(grid_spacing))
		
		# Calculate grid size with new dimensions
		var grid_width = (tile_size + grid_spacing) * GRID_SIZE - grid_spacing
		var grid_height = grid_width
		grid_container.custom_minimum_size = Vector2(grid_width, grid_height)
		
		# Center game area
		var game_area = get_node_or_null("VBox/GameArea")
		if game_area:
			game_area.custom_minimum_size = Vector2(grid_width, grid_height)
	
	# Adaptive font sizes
	update_font_sizes(viewport_size)
	
	# Force layout update
	await get_tree().process_frame
	force_layout_update()

func force_layout_update():
	# Force layout update for all containers
	if grid_container:
		grid_container.queue_redraw()
		grid_container.queue_sort()

func update_tile_sizes():
	if tile_grid.size() > 0:
		for row in tile_grid:
			for tile in row:
				tile.custom_minimum_size = Vector2(tile_size, tile_size)

func update_font_sizes(viewport_size: Vector2):
	var is_mobile = OS.has_feature('mobile') or OS.has_feature('android') or OS.has_feature('ios')
	
	# Базовый размер с учетом минимального измерения
	var min_dimension = min(viewport_size.x, viewport_size.y)
	var base_size = min_dimension * 0.03
	
	if is_mobile:
		base_size = min_dimension * 0.025
	
	base_size = clamp(base_size, min_font_size, max_font_size)
	
	# Title
	if title_label:
		var title_size = int(base_size * 1.8)
		title_size = clamp(title_size, 24, 48)
		title_label.add_theme_font_size_override("font_size", title_size)
	
	# Score labels - уменьшаем размер для малых экранов
	if score_label:
		var score_size = int(base_size * 1.4)
		score_size = clamp(score_size, 16, 32)
		score_label.add_theme_font_size_override("font_size", score_size)
	
	if best_score_label:
		var best_size = int(base_size * 1.4)
		best_size = clamp(best_size, 16, 32)
		best_score_label.add_theme_font_size_override("font_size", best_size)
	
	# Buttons - адаптивный размер
	var buttons = [restart_button, menu_button, settings_button, how_to_play_button]
	for button in buttons:
		if button:
			var button_font_size = int(base_size * 1.0)
			button_font_size = clamp(button_font_size, 14, 22)
			button.add_theme_font_size_override("font_size", button_font_size)
	
	# Time display - адаптивный размер
	if time_display:
		var time_size = int(base_size * 1.2)
		time_size = clamp(time_size, 18, 28)
		time_display.add_theme_font_size_override("font_size", time_size)

func setup_mobile_layout(viewport_size: Vector2, min_dimension: float):
	print("Setting up mobile layout")
	
	# Более агрессивное уменьшение для мобильных
	tile_size = max(min_tile_size * 0.8, min_dimension * tile_size_ratio * 0.6)
	tile_size = min(tile_size, max_tile_size * 0.6)
	grid_spacing = tile_size * grid_spacing_ratio * 0.6
	
	update_tile_sizes()
	
	if grid_container:
		grid_container.add_theme_constant_override("h_separation", int(grid_spacing))
		grid_container.add_theme_constant_override("v_separation", int(grid_spacing))
		
		var grid_width = (tile_size + grid_spacing) * GRID_SIZE - grid_spacing
		var grid_height = grid_width
		grid_container.custom_minimum_size = Vector2(grid_width, grid_height)
		
		var game_area = get_node_or_null("VBox/GameArea")
		if game_area:
			game_area.custom_minimum_size = Vector2(grid_width, grid_height)
	
	# Адаптивные размеры шрифтов
	update_font_sizes(viewport_size)
	
	await get_tree().process_frame
	force_layout_update()

func save_best_score():
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_var(best_score)
		save_file.close()

func load_best_score():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if save_file:
			best_score = save_file.get_var()
			save_file.close()
	
	update_best_score_display()

func _on_menu_pressed():
	print("Menu button pressed")
	
	# Отправка события в Game Ready API
	if game_ready_api and game_ready_api.has_method("send_analytics_event"):
		game_ready_api.send_analytics_event("menu_clicked", {
			"location": "game",
			"action": "return_to_menu"
		})
	
	# Сохраняем текущую игру
	save_current_game()
	
	# Безопасная смена сцены
	call_deferred("change_to_menu")

func change_to_menu():
	# Используем call_deferred для безопасности
	var error = get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	if error != OK:
		print("ERROR: Failed to change scene to MainMenu: ", error)

func check_for_saved_game():
	if SaveManager and SaveManager.has_saved_game():
		var saved_game = SaveManager.get_saved_game()
		if saved_game.has("grid") and saved_game.has("score") and saved_game.has("moves"):
			load_saved_game(saved_game)
			is_loading_saved_game = true

func load_saved_game(saved_game: Dictionary):
	var saved_grid = saved_game["grid"].duplicate(true)
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if i < saved_grid.size() and j < saved_grid[i].size():
				game_logic.grid[i][j] = int(saved_grid[i][j])
	
	game_logic.score = saved_game["score"]
	moves_count = saved_game["moves"]
	
	_on_grid_changed(game_logic.grid)
	_on_score_changed(game_logic.score)
	
	print("Loaded saved game with score ", game_logic.score, " and moves ", moves_count)

func save_current_game():
	if SaveManager and not is_game_over:
		SaveManager.save_current_game(game_logic.grid, game_logic.score, moves_count)

func get_highest_tile_value() -> int:
	var highest = 0
	for row in game_logic.grid:
		for cell_value in row:
			if cell_value > highest:
				highest = cell_value
	return highest

func finalize_game_session(won: bool):
	if SaveManager:
		var highest_tile = get_highest_tile_value()
		var play_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
		
		SaveManager.update_game_finished(game_logic.score, highest_tile, moves_count, won)
		SaveManager.update_play_time(play_time)
		
		# Сохраняем в таблицу лидеров
		if LeaderboardManager and LeaderboardManager.has_method("save_score"):
			LeaderboardManager.save_score(game_logic.score, highest_tile)
		
		check_achievements(highest_tile, moves_count, won)
		
		# Уведомляем Poki о завершении игрового процесса
		if game_ready_api and game_ready_api.has_method("gameplay_stop"):
			game_ready_api.gameplay_stop()
		
		# Активируем счастливый момент при высоком счете
		if game_ready_api and game_ready_api.has_method("happy_time"):
			if game_logic.score > 1000:
				game_ready_api.happy_time(30.0)
			elif won:
				game_ready_api.happy_time(15.0)

func check_achievements(highest_tile: int, moves: int, won: bool):
	if not SaveManager:
		return
	
	# Basic tile achievements
	if highest_tile >= 128:
		SaveManager.unlock_achievement("reach_128")
	if highest_tile >= 256:
		SaveManager.unlock_achievement("reach_256")
	if highest_tile >= 512:
		SaveManager.unlock_achievement("reach_512")
	if highest_tile >= 1024:
		SaveManager.unlock_achievement("reach_1024")
	if highest_tile >= 2048:
		SaveManager.unlock_achievement("reach_2048")
	
	# Efficiency achievements
	if won and moves <= 200:
		SaveManager.unlock_achievement("efficient_win")
	if won and moves <= 150:
		SaveManager.unlock_achievement("speed_demon")
	
	# First game achievement
	if SaveManager.get_total_games_played() == 1:
		SaveManager.unlock_achievement("first_game")

	# Time Attack achievements
	if game_logic.current_mode == GameModeManager.GameMode.TIME_ATTACK:
		if won:
			SaveManager.unlock_achievement("time_master")
			
			# Check remaining time for fast_thinker
			var current_time = Time.get_ticks_msec() / 1000.0
			var time_used = current_time - game_logic.game_start_time
			var time_left = game_logic.time_limit - time_used
			
			if time_left >= 30:
				SaveManager.unlock_achievement("fast_thinker")
	
	# Survival achievements
	elif game_logic.current_mode == GameModeManager.GameMode.SURVIVAL:
		if moves >= 100:
			SaveManager.unlock_achievement("survivor")
		if moves >= 300:
			SaveManager.unlock_achievement("endurance_champ")
		if highest_tile >= 512 and game_logic.obstacle_count >= 5:
			SaveManager.unlock_achievement("obstacle_master")

func _on_watch_ad_pressed():
	print("Showing rewarded ad for continue")
	
	# Pause music during ad
	if SoundManager:
		SoundManager.force_pause_music()
	
	# Используем Poki rewarded ads
	if game_ready_api and game_ready_api.has_method("show_rewarded_ad"):
		var ad_success = await game_ready_api.show_rewarded_ad()
		
		if ad_success:
			restore_from_ad()
			
			if game_over_panel_instance:
				game_over_panel_instance.hide_panel()
			
			is_game_over = false
			
			# Restart timers
			if game_logic.current_mode == GameModeManager.GameMode.TIME_ATTACK:
				start_time_attack_timer()
		else:
			print("Rewarded ad failed or was closed")
	else:
		# Fallback для мок режима
		await get_tree().create_timer(2.0).timeout
		restore_from_ad()
		
		if game_over_panel_instance:
			game_over_panel_instance.hide_panel()
		
		is_game_over = false
		
		if game_logic.current_mode == GameModeManager.GameMode.TIME_ATTACK:
			start_time_attack_timer()

func restore_from_ad():
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if game_logic.grid[i][j] > 4 and randf() < 0.3:
				game_logic.grid[i][j] = 0
	
	game_logic.add_random_tile()
	_on_grid_changed(game_logic.grid)

func _on_settings_pressed():
	if not settings_panel:
		create_settings_panel()
	settings_panel.visible = true

func create_settings_panel():
	if settings_panel and is_instance_valid(settings_panel):
		settings_panel.queue_free()
	
	settings_panel = Panel.new()
	add_child(settings_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = settings_panel_color
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.size = Vector2(600, 500)
	
	var vbox = VBoxContainer.new()
	settings_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	
	# Settings title
	var settings_title = Label.new()
	if LocalizationManager:
		settings_title.text = LocalizationManager.get_text("settings")
	else:
		settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))
	settings_title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(settings_title)
	
	# Добавляем ScrollContainer для настроек
	var scroll_container = ScrollContainer.new()
	vbox.add_child(scroll_container)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 350)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_container.add_child(scroll_vbox)
	scroll_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_vbox.add_theme_constant_override("separation", 15)
	
	# Language selection
	create_language_controls(scroll_vbox)
	
	# Background selection
	create_background_controls(scroll_vbox)
	
	# Music track selection
	create_music_controls(scroll_vbox)
	
	# Volume controls
	create_volume_controls(scroll_vbox)
	
	# Close button
	var close_button = Button.new()
	if LocalizationManager:
		close_button.text = LocalizationManager.get_text("close")
	else:
		close_button.text = "CLOSE"
	if close_button.is_connected("pressed", _on_settings_close_pressed):
		close_button.disconnect("pressed", _on_settings_close_pressed)
	close_button.pressed.connect(_on_settings_close_pressed)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.custom_minimum_size = Vector2(0, 50)
	close_button.focus_mode = Control.FOCUS_NONE
	vbox.add_child(close_button)
	
	settings_panel.visible = false

func create_language_controls(parent: VBoxContainer):
	var language_container = HBoxContainer.new()
	parent.add_child(language_container)
	language_container.add_theme_constant_override("separation", 10)
	
	var language_label = Label.new()
	if LocalizationManager:
		language_label.text = LocalizationManager.get_text("language") + ""
	else:
		language_label.text = "Language"
	language_label.custom_minimum_size.x = 150
	language_label.add_theme_color_override("font_color", Color.WHITE)
	language_label.add_theme_font_size_override("font_size", 24)
	language_container.add_child(language_label)
	
	var language_option = OptionButton.new()
	if LocalizationManager:
		var available_languages = LocalizationManager.get_available_languages()
		for i in range(available_languages.size()):
			var lang = available_languages[i]
			var lang_name = LocalizationManager.get_language_name(lang)
			language_option.add_item(lang_name, i)
		
		var current_lang = LocalizationManager.get_current_language()
		var current_index = available_languages.find(current_lang)
		if current_index != -1:
			language_option.selected = current_index
	
	if language_option.is_connected("item_selected", _on_language_changed):
		language_option.disconnect("item_selected", _on_language_changed)
	language_option.item_selected.connect(_on_language_changed)
	language_option.add_theme_font_size_override("font_size", 20)
	language_option.custom_minimum_size = Vector2(200, 40)
	language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_container.add_child(language_option)

func create_background_controls(parent: VBoxContainer):
	var bg_container = HBoxContainer.new()
	parent.add_child(bg_container)
	bg_container.add_theme_constant_override("separation", 10)
	
	var bg_label = Label.new()
	if LocalizationManager:
		bg_label.text = LocalizationManager.get_text("background") + ""
	else:
		bg_label.text = "Background"
	bg_label.custom_minimum_size.x = 150
	bg_label.add_theme_color_override("font_color", Color.WHITE)
	bg_label.add_theme_font_size_override("font_size", 24)
	bg_container.add_child(bg_label)
	
	var bg_prev_button = Button.new()
	if LocalizationManager:
		bg_prev_button.text = LocalizationManager.get_text("previous")
	else:
		bg_prev_button.text = "PREV"
	if bg_prev_button.is_connected("pressed", _on_background_previous):
		bg_prev_button.disconnect("pressed", _on_background_previous)
	bg_prev_button.pressed.connect(_on_background_previous)
	bg_prev_button.add_theme_font_size_override("font_size", 20)
	bg_prev_button.custom_minimum_size = Vector2(80, 40)
	bg_container.add_child(bg_prev_button)
	
	var bg_index_label_ref = Label.new()
	if AssetManager:
		bg_index_label_ref.text = str(AssetManager.current_background_index + 1) + "/" + str(AssetManager.get_background_count())
	else:
		bg_index_label_ref.text = "1/1"
	bg_index_label_ref.add_theme_color_override("font_color", Color.WHITE)
	bg_index_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg_index_label_ref.custom_minimum_size.x = 80
	bg_index_label_ref.add_theme_font_size_override("font_size", 20)
	bg_container.add_child(bg_index_label_ref)
	
	var bg_next_button = Button.new()
	if LocalizationManager:
		bg_next_button.text = LocalizationManager.get_text("next")
	else:
		bg_next_button.text = "NEXT"
	if bg_next_button.is_connected("pressed", _on_background_next):
		bg_next_button.disconnect("pressed", _on_background_next)
	bg_next_button.pressed.connect(_on_background_next)
	bg_next_button.add_theme_font_size_override("font_size", 20)
	bg_next_button.custom_minimum_size = Vector2(80, 40)
	bg_container.add_child(bg_next_button)

func create_music_controls(parent: VBoxContainer):
	var music_container = HBoxContainer.new()
	parent.add_child(music_container)
	music_container.add_theme_constant_override("separation", 10)
	
	var music_label = Label.new()
	if LocalizationManager:
		music_label.text = LocalizationManager.get_text("music_track") + ""
	else:
		music_label.text = "Music"
	music_label.custom_minimum_size.x = 150
	music_label.add_theme_color_override("font_color", Color.WHITE)
	music_label.add_theme_font_size_override("font_size", 24)
	music_container.add_child(music_label)
	
	var music_prev_button = Button.new()
	if LocalizationManager:
		music_prev_button.text = LocalizationManager.get_text("previous")
	else:
		music_prev_button.text = "Previous"
	if music_prev_button.is_connected("pressed", _on_music_previous):
		music_prev_button.disconnect("pressed", _on_music_previous)
	music_prev_button.pressed.connect(_on_music_previous)
	music_prev_button.add_theme_font_size_override("font_size", 20)
	music_prev_button.custom_minimum_size = Vector2(80, 40)
	music_container.add_child(music_prev_button)
	
	var music_index_label_ref = Label.new()
	if AssetManager:
		music_index_label_ref.text = str(AssetManager.current_music_index + 1) + "/" + str(AssetManager.get_music_count())
	else:
		music_index_label_ref.text = "1/1"
	music_index_label_ref.add_theme_color_override("font_color", Color.WHITE)
	music_index_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_index_label_ref.custom_minimum_size.x = 80
	music_index_label_ref.add_theme_font_size_override("font_size", 20)
	music_container.add_child(music_index_label_ref)
	
	var music_next_button = Button.new()
	if LocalizationManager:
		music_next_button.text = LocalizationManager.get_text("next")
	else:
		music_next_button.text = "Next"
	if music_next_button.is_connected("pressed", _on_music_next):
		music_next_button.disconnect("pressed", _on_music_next)
	music_next_button.pressed.connect(_on_music_next)
	music_next_button.add_theme_font_size_override("font_size", 20)
	music_next_button.custom_minimum_size = Vector2(80, 40)
	music_container.add_child(music_next_button)

func create_volume_controls(parent: VBoxContainer):
	# Master Volume
	var master_container = HBoxContainer.new()
	parent.add_child(master_container)
	master_container.add_theme_constant_override("separation", 10)
	
	var master_label = Label.new()
	if LocalizationManager:
		master_label.text = LocalizationManager.get_text("master_volume") + ""
	else:
		master_label.text = "Master Volume"
	master_label.custom_minimum_size.x = 150
	master_label.add_theme_color_override("font_color", Color.WHITE)
	master_label.add_theme_font_size_override("font_size", 24)
	master_container.add_child(master_label)
	
	var master_volume_slider = HSlider.new()
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.1
	master_volume_slider.value = 0.8
	master_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_volume_slider.custom_minimum_size.y = 30
	if master_volume_slider.is_connected("value_changed", _on_master_volume_changed):
		master_volume_slider.disconnect("value_changed", _on_master_volume_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	master_container.add_child(master_volume_slider)
	
	# Music Volume
	var music_container = HBoxContainer.new()
	parent.add_child(music_container)
	music_container.add_theme_constant_override("separation", 10)
	
	var music_label = Label.new()
	if LocalizationManager:
		music_label.text = LocalizationManager.get_text("music_volume") + ""
	else:
		music_label.text = "Music Volume"
	music_label.custom_minimum_size.x = 150
	music_label.add_theme_color_override("font_color", Color.WHITE)
	music_label.add_theme_font_size_override("font_size", 24)
	music_container.add_child(music_label)
	
	var music_volume_slider = HSlider.new()
	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.1
	music_volume_slider.value = 0.4
	music_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_volume_slider.custom_minimum_size.y = 30
	if music_volume_slider.is_connected("value_changed", _on_music_volume_changed):
		music_volume_slider.disconnect("value_changed", _on_music_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	music_container.add_child(music_volume_slider)

# Settings control functions
func _on_language_changed(index: int):
	if LocalizationManager:
		var available_languages = LocalizationManager.get_available_languages()
		if index < available_languages.size():
			LocalizationManager.set_language(available_languages[index])
			update_copyright_text()
			update_localization()

func _on_background_previous():
	if AssetManager:
		AssetManager.previous_background()
		AssetManager.save_asset_settings()
		update_background()
		update_background_counter()

func _on_background_next():
	if AssetManager:
		AssetManager.next_background()
		AssetManager.save_asset_settings()
		update_background()
		update_background_counter()

func _on_music_previous():
	if AssetManager:
		print("Previous music track pressed in settings")
		AssetManager.previous_music()
		AssetManager.save_asset_settings()
		update_music()
		update_music_counter()

func _on_music_next():
	if AssetManager:
		print("Next music track pressed in settings")
		AssetManager.next_music()
		AssetManager.save_asset_settings()
		update_music()
		update_music_counter()

func update_background_counter():
	var bg_index_label_ref = get_node_or_null("SettingsPanel/.../BackgroundIndexLabel")
	if bg_index_label_ref and AssetManager:
		bg_index_label_ref.text = str(AssetManager.current_background_index + 1) + "/" + str(AssetManager.get_background_count())

func update_music_counter():
	var music_index_label_ref = get_node_or_null("SettingsPanel/.../MusicIndexLabel")
	if music_index_label_ref and AssetManager:
		music_index_label_ref.text = str(AssetManager.current_music_index + 1) + "/" + str(AssetManager.get_music_count())

func _on_master_volume_changed(value: float):
	if SoundManager:
		SoundManager.set_master_volume(value)

func _on_music_volume_changed(value: float):
	if SoundManager:
		SoundManager.set_music_volume(value)

func _on_settings_close_pressed():
	if settings_panel:
		settings_panel.visible = false

func update_background():
	if bg_texture_rect and AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if bg_texture:
			bg_texture_rect.texture = bg_texture

func update_music():
	if SoundManager and AssetManager:
		var music_stream = AssetManager.get_current_music()
		if music_stream:
			print("Updating music in settings to track: ", AssetManager.current_music_index)
			SoundManager.music_player.stream = music_stream
			if SoundManager.music_player.playing:
				SoundManager.music_player.stop()
			SoundManager.music_player.play()
			print("Music updated successfully in settings")

# Mode-specific UI functions
func setup_mode_ui():
	var current_mode = GameModeManager.get_current_mode()
	print("Setting up mode UI for ", GameModeManager.get_mode_name(current_mode))
	
	# First hide all mode elements
	hide_mode_specific_ui()
	
	# Then show needed ones depending on mode
	match current_mode:
		GameModeManager.GameMode.TIME_ATTACK:
			setup_time_attack_ui()
		GameModeManager.GameMode.SURVIVAL:
			setup_survival_ui()
		GameModeManager.GameMode.CLASSIC:
			setup_classic_ui()

func setup_time_display():
	print("Setting up TimeDisplay...")
	
	# Если TimeDisplay уже существует, удаляем его
	if time_display and is_instance_valid(time_display):
		time_display.queue_free()
		time_display = null
	
	# Создаем новый TimeDisplay
	var time_display_scene_path = "res://scenes/ui/TimeDisplay.tscn"
	if ResourceLoader.exists(time_display_scene_path):
		var time_display_scene = load(time_display_scene_path)
		time_display = time_display_scene.instantiate()
		print("TimeDisplay loaded from scene")
	else:
		# Fallback: создаем простой TimeDisplay программно
		time_display = Control.new()
		time_display.name = "TimeDisplay"
		
		# Создаем фон
		var background = ColorRect.new()
		background.name = "Background"
		background.color = Color(0.1, 0.1, 0.2, 0.8)
		background.corner_radius_top_left = 8
		background.corner_radius_top_right = 8
		background.corner_radius_bottom_left = 8
		background.corner_radius_bottom_right = 8
		time_display.add_child(background)
		
		# Создаем метку для времени
		var time_label = Label.new()
		time_label.name = "TimeLabel"
		time_label.text = "03:00"
		time_label.add_theme_font_size_override("font_size", 24)
		time_label.add_theme_color_override("font_color", Color.WHITE)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_display.add_child(time_label)
		
		# Назначаем скрипт TimeDisplay
		var time_display_script = load("res://scripts/ui/TimeDisplay.gd")
		time_display.set_script(time_display_script)
		
		print("TimeDisplay created programmatically")
	
	# Добавляем в сцену
	add_child(time_display)
	
	# Настраиваем размер и позицию
	time_display.custom_minimum_size = Vector2(150, 40)
	time_display.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	time_display.position = Vector2(0, 10)
	
	# Убеждаемся, что TimeDisplay поверх других элементов
	time_display.z_index = 100
	
	# Скрываем до начала Time Attack
	time_display.visible = false

func setup_time_attack_ui():
	print("Setting up Time Attack UI")
	
	# Убеждаемся, что TimeDisplay существует
	if not time_display or not is_instance_valid(time_display):
		setup_time_display()
	
	if time_display:
		time_display.visible = true
		var time_limit = GameModeManager.get_time_limit()
		time_display.update_time(time_limit)
		
		# Принудительно обновляем отображение
		time_display.queue_redraw()
		
		print("Time Attack UI setup complete - TimeDisplay should be visible")
	else:
		print("ERROR: TimeDisplay not available for Time Attack mode")
	
	# Hide obstacles label in time attack
	if obstacles_label:
		obstacles_label.visible = false

func setup_survival_ui():
	# Obstacles label
	if obstacles_label:
		obstacles_label.visible = true
		if LocalizationManager:
			obstacles_label.text = LocalizationManager.get_text("obstacles") + " 0"
		else:
			obstacles_label.text = "Obstacles 0"
	
	# Hide timer display in survival mode
	if time_display:
		time_display.visible = false

func setup_classic_ui():
	# Hide all mode-specific UI in classic mode
	if time_display:
		time_display.visible = false
	if obstacles_label:
		obstacles_label.visible = false

func hide_mode_specific_ui():
	if time_display:
		time_display.visible = false
	if obstacles_label:
		obstacles_label.visible = false

func _on_obstacles_spawned(obstacle_count: int):
	if obstacles_label and obstacles_label.visible:
		if LocalizationManager:
			obstacles_label.text = LocalizationManager.get_text("obstacles") + " " + str(obstacle_count)
		else:
			obstacles_label.text = "Obstacles " + str(obstacle_count)
	
	_on_grid_changed(game_logic.get_grid())

func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60.0
	var secs = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Сохраняем при закрытии
			save_current_game()
		
		NOTIFICATION_APPLICATION_PAUSED:
			# Паузим таймеры при паузе приложения
			if time_attack_timer:
				time_attack_timer.paused = true
		
		NOTIFICATION_APPLICATION_RESUMED:
			# Возобновляем таймеры
			if time_attack_timer:
				time_attack_timer.paused = false
