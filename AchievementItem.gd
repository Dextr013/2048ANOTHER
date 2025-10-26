class_name AchievementItem
extends Control

# Node references
@onready var name_label: Label = $HBoxContainer/ContentContainer/NameLabel
@onready var desc_label: Label = $HBoxContainer/ContentContainer/DescLabel
@onready var status_label: Label = $HBoxContainer/StatusLabel

# Background
@onready var background_panel: Panel = $BackgroundPanel

# Achievement data
var achievement_data: Dictionary
var is_unlocked: bool = false

func _ready():
	# Setup dark background
	setup_background()

func setup(data: Dictionary, unlocked: bool):
	achievement_data = data
	is_unlocked = unlocked
	update_display()

func setup_background():
	if not background_panel:
		# Create background panel if it doesn't exist
		background_panel = Panel.new()
		add_child(background_panel)
		background_panel.z_index = -1
		background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Set dark background with some transparency
	background_panel.add_theme_stylebox_override("panel", create_dark_stylebox())

func create_dark_stylebox() -> StyleBoxFlat:
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Dark semi-transparent
	style_box.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.content_margin_left = 10
	style_box.content_margin_top = 10
	style_box.content_margin_right = 10
	style_box.content_margin_bottom = 10
	return style_box

func update_display():
	if not achievement_data.is_empty():
		# Set name and description based on current language
		if LocalizationManager:
			var current_lang = LocalizationManager.get_current_language()
			
			if name_label:
				if current_lang == LocalizationManager.Language.RUSSIAN:
					name_label.text = achievement_data.get("name_ru", "Unknown")
				else:
					name_label.text = achievement_data.get("name_en", "Unknown")
			
			if desc_label:
				if current_lang == LocalizationManager.Language.RUSSIAN:
					desc_label.text = achievement_data.get("desc_ru", "No description")
				else:
					desc_label.text = achievement_data.get("desc_en", "No description")
		else:
			# Fallback to English
			if name_label:
				name_label.text = achievement_data.get("name_en", "Unknown")
			if desc_label:
				desc_label.text = achievement_data.get("desc_en", "No description")
		
		# Set status
		if status_label:
			if is_unlocked:
				if LocalizationManager:
					status_label.text = LocalizationManager.get_text("unlocked")
				else:
					status_label.text = "UNLOCKED"
				status_label.modulate = Color.GREEN
				# Light text for unlocked achievements
				if name_label: name_label.modulate = Color.WHITE
				if desc_label: desc_label.modulate = Color.LIGHT_GRAY
			else:
				if LocalizationManager:
					status_label.text = LocalizationManager.get_text("locked")
				else:
					status_label.text = "LOCKED"
				status_label.modulate = Color.RED
				# Dimmed text for locked achievements
				if name_label: name_label.modulate = Color.GRAY
				if desc_label: desc_label.modulate = Color.DARK_GRAY

func update_localization():
	update_display()
