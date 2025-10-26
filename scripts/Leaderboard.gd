extends Control

# Node references
@onready var background: TextureRect = $Background
@onready var title_label: Label = $VBox/TitleLabel
@onready var stats_container: VBoxContainer = $VBox/StatsContainer
@onready var leaderboard_list: VBoxContainer = $VBox/ScrollContainer/LeaderboardList
@onready var back_button: Button = $VBox/BackButton
@onready var copyright_label: Label = $CopyrightLabel

# Entry scene
var entry_scene = preload("res://scenes/ui/leaderboard_entry.tscn")

# Inspector-editable panel colors
@export var leaderboard_panel_color: Color = Color(0.98, 0.97, 0.94, 0.95)

func _ready():
	setup_ui()
	call_deferred("populate_leaderboard")
	update_localization()

func setup_ui():
	# Connect signals
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Apply theme and styling
	apply_theme()
	
	# Setup background
	if background and AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if bg_texture:
			background.texture = bg_texture

func apply_theme():
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	add_theme_stylebox_override("panel", main_style)
	
	# Адаптивные размеры шрифтов
	var viewport_size = get_viewport().get_visible_rect().size
	var base_font_size = viewport_size.x * 0.025
	base_font_size = clamp(base_font_size, 18, 48)
	
	# Title
	if title_label:
		var title_size = int(base_font_size * 1.8)
		title_size = clamp(title_size, 32, 64)
		title_label.add_theme_font_size_override("font_size", title_size)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.add_theme_color_override("font_outline_color", Color.BLACK)
		title_label.add_theme_constant_override("outline_size", 10)
	
	# Buttons
	if back_button:
		var button_size = int(base_font_size * 1.5)
		button_size = clamp(button_size, 24, 48)
		back_button.add_theme_font_size_override("font_size", button_size)
		back_button.add_theme_color_override("font_color", Color.WHITE)
		back_button.add_theme_color_override("font_outline_color", Color.BLACK)
		back_button.add_theme_constant_override("outline_size", 8)
	
	# Copyright
	if copyright_label:
		var copyright_size = int(base_font_size * 0.8)
		copyright_size = clamp(copyright_size, 14, 24)
		update_copyright_text()
		copyright_label.add_theme_font_size_override("font_size", copyright_size)
		copyright_label.add_theme_color_override("font_color", Color.WHITE)
		copyright_label.add_theme_color_override("font_outline_color", Color.BLACK)
		copyright_label.add_theme_constant_override("outline_size", 6)

func populate_leaderboard():
	if not stats_container or not leaderboard_list:
		return
	
	# Clear existing children
	for child in stats_container.get_children():
		child.queue_free()
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	# Create stats summary
	create_stats_summary()
	
	# Add separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	stats_container.add_child(separator)
	
	# Create leaderboard entries
	create_leaderboard_entries()

func create_stats_summary():
	if not SaveManager:
		create_no_data_label()
		return
	
	# Overall stats container
	var overall_stats = VBoxContainer.new()
	overall_stats.add_theme_constant_override("separation", 10)
	stats_container.add_child(overall_stats)
	
	# Best score
	var best_score_container = HBoxContainer.new()
	best_score_container.add_theme_constant_override("separation", 10)
	overall_stats.add_child(best_score_container)
	
	var best_score_label = create_outlined_label()
	if LocalizationManager:
		best_score_label.text = LocalizationManager.get_text("best_score") + ": "
	else:
		best_score_label.text = "Best Score: "
	best_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	best_score_container.add_child(best_score_label)
	
	var best_score_value = create_outlined_label()
	best_score_value.text = str(SaveManager.get_highest_score())
	best_score_container.add_child(best_score_value)
	
	# Games played
	var games_played_container = HBoxContainer.new()
	games_played_container.add_theme_constant_override("separation", 10)
	overall_stats.add_child(games_played_container)
	
	var games_played_label = create_outlined_label()
	if LocalizationManager:
		games_played_label.text = LocalizationManager.get_text("games_played") + ": "
	else:
		games_played_label.text = "Games Played: "
	games_played_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_played_container.add_child(games_played_label)
	
	var games_played_value = create_outlined_label()
	games_played_value.text = str(SaveManager.get_total_games_played())
	games_played_container.add_child(games_played_value)
	
	# Games won
	var games_won_container = HBoxContainer.new()
	games_won_container.add_theme_constant_override("separation", 10)
	overall_stats.add_child(games_won_container)
	
	var games_won_label = create_outlined_label()
	if LocalizationManager:
		games_won_label.text = LocalizationManager.get_text("games_won") + ": "
	else:
		games_won_label.text = "Games Won: "
	games_won_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_won_container.add_child(games_won_label)
	
	var games_won_value = create_outlined_label()
	games_won_value.text = str(SaveManager.get_total_games_won())
	games_won_container.add_child(games_won_value)
	
	# Win rate
	var win_rate_container = HBoxContainer.new()
	win_rate_container.add_theme_constant_override("separation", 10)
	overall_stats.add_child(win_rate_container)
	
	var win_rate_label = create_outlined_label()
	if LocalizationManager:
		win_rate_label.text = LocalizationManager.get_text("win_rate") + ": "
	else:
		win_rate_label.text = "Win Rate: "
	win_rate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_rate_container.add_child(win_rate_label)
	
	var win_rate_value = create_outlined_label()
	var win_rate = 0.0
	if SaveManager.get_total_games_played() > 0:
		win_rate = (float(SaveManager.get_total_games_won()) / float(SaveManager.get_total_games_played())) * 100.0
	win_rate_value.text = "%.1f%%" % win_rate
	win_rate_container.add_child(win_rate_value)

func create_leaderboard_entries():
	# Create header
	var header_item = create_leaderboard_header()
	leaderboard_list.add_child(header_item)
	
	# Get top scores
	var top_scores = get_top_scores()
	
	if top_scores.is_empty():
		create_no_scores_label()
		return
	
	# Create entries for top scores
	for i in range(min(top_scores.size(), 10)):
		var score_entry = top_scores[i]
		var entry_item = create_leaderboard_entry(i + 1, score_entry)
		if entry_item:
			leaderboard_list.add_child(entry_item)

func create_outlined_label() -> Label:
	var label = Label.new()
	
	# Адаптивный размер
	var viewport_size = get_viewport().get_visible_rect().size
	var base_font_size = viewport_size.x * 0.02
	base_font_size = clamp(base_font_size, 16, 36)
	
	label.add_theme_font_size_override("font_size", int(base_font_size))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	return label

func create_leaderboard_header() -> Control:
	var header = Panel.new()
	
	# Адаптивная высота
	var viewport_size = get_viewport().get_visible_rect().size
	var header_height = viewport_size.y * 0.08
	header_height = clamp(header_height, 50, 80)
	header.custom_minimum_size = Vector2(0, header_height)
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header.add_theme_stylebox_override("panel", header_style)
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	header.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Адаптивные ширины колонок
	var col_width = viewport_size.x * 0.12
	col_width = clamp(col_width, 80, 150)
	
	# Rank
	var rank_label = create_outlined_label()
	if LocalizationManager:
		rank_label.text = LocalizationManager.get_text("rank")
	else:
		rank_label.text = "Rank"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.custom_minimum_size = Vector2(col_width, 0)
	container.add_child(rank_label)
	
	# Score
	var score_label = create_outlined_label()
	if LocalizationManager:
		score_label.text = LocalizationManager.get_text("score")
	else:
		score_label.text = "Score"
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(score_label)
	
	# Highest Tile
	var tile_label = create_outlined_label()
	if LocalizationManager:
		tile_label.text = LocalizationManager.get_text("highest_tile")
	else:
		tile_label.text = "Tile"
	tile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile_label.custom_minimum_size = Vector2(col_width, 0)
	container.add_child(tile_label)
	
	# Date
	var date_label = create_outlined_label()
	if LocalizationManager:
		date_label.text = LocalizationManager.get_text("date")
	else:
		date_label.text = "Date"
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.custom_minimum_size = Vector2(col_width, 0)
	container.add_child(date_label)
	
	return header

func create_leaderboard_entry(rank: int, score_data: Dictionary) -> LeaderboardEntry:
	if not entry_scene:
		push_error("Leaderboard entry scene not loaded!")
		return null
	
	var entry = entry_scene.instantiate()
	entry.setup(rank, score_data)
	return entry

func get_top_scores() -> Array:
	if not SaveManager:
		return []
	
	# Try to get scores from LeaderboardManager first
	if LeaderboardManager and LeaderboardManager.has_method("get_leaderboard"):
		var scores = LeaderboardManager.get_leaderboard()
		if not scores.is_empty():
			return scores
	
	# Fallback to SaveManager data
	var dummy_scores = []
	if SaveManager.get_highest_score() > 0:
		dummy_scores.append({
			"score": SaveManager.get_highest_score(),
			"highest_tile": SaveManager.get_highest_tile() if SaveManager.has_method("get_highest_tile") else 2048,
			"date": Time.get_datetime_string_from_system()
		})
	
	return dummy_scores  # Исправлено - убрано дублирование return

func create_no_data_label():
	var no_data_label = create_outlined_label()
	if LocalizationManager:
		no_data_label.text = LocalizationManager.get_text("no_data_available")
	else:
		no_data_label.text = "No data available"
	no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(no_data_label)

func create_no_scores_label():
	var no_scores_label = create_outlined_label()
	if LocalizationManager:
		no_scores_label.text = LocalizationManager.get_text("no_scores")
	else:
		no_scores_label.text = "No scores yet - play some games!"
	no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_list.add_child(no_scores_label)

func update_localization():
	if not LocalizationManager:
		return
	
	# Update title
	if title_label:
		title_label.text = LocalizationManager.get_text("leaderboard")
	
	# Update back button
	if back_button:
		back_button.text = LocalizationManager.get_text("menu")
	
	# Update copyright
	update_copyright_text()
	
	# Repopulate leaderboard with updated language
	call_deferred("populate_leaderboard")

func update_copyright_text():
	if copyright_label and LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "© 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "© 2025 13.ink - All rights reserved"

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Handle window resize
func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_WM_SIZE_CHANGED:
		# Refresh the layout (отложенно для оптимизации)
		call_deferred("populate_leaderboard")
