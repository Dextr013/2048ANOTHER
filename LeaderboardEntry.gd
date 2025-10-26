class_name LeaderboardEntry
extends Panel

@onready var rank_label: Label = $HBoxContainer/RankLabel
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var tile_label: Label = $HBoxContainer/TileLabel
@onready var date_label: Label = $HBoxContainer/DateLabel

var entry_rank: int = 0
var entry_data: Dictionary = {}
var _nodes_ready: bool = false

func _ready():
	_nodes_ready = true
	# Если данные уже были установлены через setup(), обновляем отображение
	if entry_data:
		update_display()
		apply_styling()

func setup(rank: int, score_data: Dictionary):
	entry_rank = rank
	entry_data = score_data
	
	# Если узлы уже готовы, обновляем сразу
	if _nodes_ready:
		update_display()
		apply_styling()

func update_display():
	# Проверяем, что узлы инициализированы перед установкой текста
	if not _nodes_ready:
		return
	
	if rank_label:
		rank_label.text = str(entry_rank)
	if score_label:
		score_label.text = str(entry_data.get("score", 0))
	if tile_label:
		tile_label.text = str(entry_data.get("highest_tile", 0))
	if date_label:
		date_label.text = format_date(entry_data.get("date", entry_data.get("timestamp", "")))

func apply_styling():
	if not _nodes_ready:
		return
	
	var entry_style = StyleBoxFlat.new()
	
	# Color coding for labels
	if score_label:
		score_label.add_theme_color_override("font_color", Color(0.0, 0.6, 1.0, 1.0))  # Blue
	if tile_label:
		tile_label.add_theme_color_override("font_color", Color(0.0, 0.8, 0.4, 1.0))  # Green
	if date_label:
		date_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))  # Gray
	
	# Style based on rank
	match entry_rank:
		1:
			entry_style.bg_color = Color(1.0, 0.84, 0.0, 0.3)  # Gold
			entry_style.border_color = Color(1.0, 0.84, 0.0, 0.8)
			if rank_label:
				rank_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.0, 1.0))
		2:
			entry_style.bg_color = Color(0.75, 0.75, 0.75, 0.3)  # Silver
			entry_style.border_color = Color(0.75, 0.75, 0.75, 0.8)
			if rank_label:
				rank_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		3:
			entry_style.bg_color = Color(0.80, 0.50, 0.20, 0.3)  # Bronze
			entry_style.border_color = Color(0.80, 0.50, 0.20, 0.8)
			if rank_label:
				rank_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3, 1.0))
		_:
			entry_style.bg_color = Color(0.9, 0.9, 0.9, 0.2)  # Regular
			entry_style.border_color = Color(0.7, 0.7, 0.7, 0.5)
			if rank_label:
				rank_label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.39, 1.0))
	
	# Common styling
	entry_style.corner_radius_top_left = 6
	entry_style.corner_radius_top_right = 6
	entry_style.corner_radius_bottom_left = 6
	entry_style.corner_radius_bottom_right = 6
	entry_style.border_width_left = 1
	entry_style.border_width_right = 1
	entry_style.border_width_top = 1
	entry_style.border_width_bottom = 1
	
	add_theme_stylebox_override("panel", entry_style)

func format_date(timestamp: String) -> String:
	if timestamp == "" or timestamp == "--":
		return "--"
	
	# Try to parse the timestamp
	if timestamp.length() >= 10:
		# Assuming format like "YYYY-MM-DD HH:MM:SS"
		var parts = timestamp.substr(0, 10).split("-")
		if parts.size() >= 3:
			return "%s/%s" % [parts[1], parts[2]]
	
	# Fallback to current date
	var datetime = Time.get_datetime_dict_from_system()
	return "%02d/%02d" % [datetime.month, datetime.day]
