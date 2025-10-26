class_name Settings
extends Control

@onready var background: TextureRect = $Background
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var settings_content: VBoxContainer = $VBoxContainer/ScrollContainer/SettingsContent
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var copyright_label: Label = $CopyrightLabel

var master_volume: float = 1.0
var music_volume: float = 1.0
var current_background: int = 0
var current_music_track: int = 0

var master_bus_index: int = 0
var music_bus_index: int = -1

var music_track_label_ref: Label
var background_label_ref: Label

# Флаг для предотвращения множественной инициализации
var _is_initialized: bool = false

func _ready():
	if _is_initialized:
		return
	
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Быстрая инициализация
	initialize_audio_buses()
	setup_ui()
	load_settings()
	
	# Отложенная тяжелая работа
	call_deferred("deferred_setup")
	
	_is_initialized = true

func deferred_setup():
	setup_settings_content()
	update_localization()
	apply_current_background()

func initialize_audio_buses():
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")

func setup_ui():
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	if background and AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if bg_texture:
			background.texture = bg_texture

func setup_settings_content():
	if not settings_content:
		return
	
	# Очищаем существующие настройки
	for child in settings_content.get_children():
		child.queue_free()
	
	# Ждем один кадр для очистки
	await get_tree().process_frame
	
	# Добавляем секции настроек
	create_language_setting()
	create_audio_settings()
	create_appearance_settings()

func create_language_setting():
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	container.add_theme_constant_override("separation", 20)
	settings_content.add_child(container)
	
	var language_label = Label.new()
	if LocalizationManager:
		language_label.text = LocalizationManager.get_text("language") + ":"
	else:
		language_label.text = "Language:"
	language_label.add_theme_font_size_override("font_size", 36)
	language_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	language_label.modulate = Color.WHITE
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(language_label)
	
	var language_option = OptionButton.new()
	language_option.add_item("English")
	language_option.add_item("Русский")
	language_option.custom_minimum_size = Vector2(300, 60)
	language_option.add_theme_font_size_override("font_size", 36)
	
	if LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			language_option.select(1)
		else:
			language_option.select(0)
	
	language_option.item_selected.connect(_on_language_selected)
	container.add_child(language_option)

func create_audio_settings():
	create_volume_setting("master_volume", master_volume)
	create_volume_setting("music_volume", music_volume)

func create_appearance_settings():
	create_background_setting()
	create_music_track_setting()

func create_volume_setting(setting_key: String, initial_value: float):
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	container.add_theme_constant_override("separation", 20)
	settings_content.add_child(container)
	
	var label = Label.new()
	if LocalizationManager:
		label.text = LocalizationManager.get_text(setting_key) + ":"
	else:
		label.text = setting_key + ":"
	label.add_theme_font_size_override("font_size", 36)
	label.modulate = Color.WHITE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(300, 50)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial_value
	slider.value_changed.connect(_on_volume_changed.bind(setting_key))
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(int(initial_value * 100)) + "%"
	value_label.add_theme_font_size_override("font_size", 36)
	value_label.modulate = Color.WHITE
	value_label.custom_minimum_size = Vector2(80, 0)
	container.add_child(value_label)
	
	slider.value_changed.connect(func(value): value_label.text = str(int(value * 100)) + "%")

func create_background_setting():
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	container.add_theme_constant_override("separation", 20)
	settings_content.add_child(container)
	
	var label = Label.new()
	if LocalizationManager:
		label.text = LocalizationManager.get_text("background") + ":"
	else:
		label.text = "Background:"
	label.add_theme_font_size_override("font_size", 36)
	label.modulate = Color.WHITE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	var bg_container = HBoxContainer.new()
	bg_container.add_theme_constant_override("separation", 10)
	container.add_child(bg_container)
	
	var prev_btn = Button.new()
	if LocalizationManager:
		prev_btn.text = LocalizationManager.get_text("previous")
	else:
		prev_btn.text = "Previous"
	prev_btn.custom_minimum_size = Vector2(120, 60)
	prev_btn.add_theme_font_size_override("font_size", 32)
	prev_btn.pressed.connect(_on_prev_background)
	bg_container.add_child(prev_btn)
	
	background_label_ref = Label.new()
	if AssetManager:
		background_label_ref.text = str(AssetManager.current_background_index + 1) + "/" + str(AssetManager.get_background_count())
	else:
		background_label_ref.text = "1/1"
	background_label_ref.add_theme_font_size_override("font_size", 36)
	background_label_ref.modulate = Color.WHITE
	background_label_ref.custom_minimum_size = Vector2(200, 60)
	background_label_ref.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	background_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg_container.add_child(background_label_ref)
	
	var next_btn = Button.new()
	if LocalizationManager:
		next_btn.text = LocalizationManager.get_text("next")
	else:
		next_btn.text = "Next"
	next_btn.custom_minimum_size = Vector2(120, 60)
	next_btn.add_theme_font_size_override("font_size", 32)
	next_btn.pressed.connect(_on_next_background)
	bg_container.add_child(next_btn)

func create_music_track_setting():
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	container.add_theme_constant_override("separation", 20)
	settings_content.add_child(container)
	
	var label = Label.new()
	if LocalizationManager:
		label.text = LocalizationManager.get_text("music_track") + ":"
	else:
		label.text = "Music Track:"
	label.add_theme_font_size_override("font_size", 36)
	label.modulate = Color.WHITE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	var music_container = HBoxContainer.new()
	music_container.add_theme_constant_override("separation", 10)
	container.add_child(music_container)
	
	var prev_btn = Button.new()
	if LocalizationManager:
		prev_btn.text = LocalizationManager.get_text("previous")
	else:
		prev_btn.text = "Previous"
	prev_btn.custom_minimum_size = Vector2(120, 60)
	prev_btn.add_theme_font_size_override("font_size", 32)
	prev_btn.pressed.connect(_on_prev_music_track)
	music_container.add_child(prev_btn)
	
	music_track_label_ref = Label.new()
	if AssetManager:
		music_track_label_ref.text = str(AssetManager.current_music_index + 1) + "/" + str(AssetManager.get_music_count())
	else:
		music_track_label_ref.text = "1/1"
	music_track_label_ref.add_theme_font_size_override("font_size", 36)
	music_track_label_ref.modulate = Color.WHITE
	music_track_label_ref.custom_minimum_size = Vector2(200, 60)
	music_track_label_ref.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_track_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_container.add_child(music_track_label_ref)
	
	var next_btn = Button.new()
	if LocalizationManager:
		next_btn.text = LocalizationManager.get_text("next")
	else:
		next_btn.text = "Next"
	next_btn.custom_minimum_size = Vector2(120, 60)
	next_btn.add_theme_font_size_override("font_size", 32)
	next_btn.pressed.connect(_on_next_music_track)
	music_container.add_child(next_btn)

func _on_language_selected(index: int):
	if LocalizationManager:
		if index == 0:
			LocalizationManager.set_language(LocalizationManager.Language.ENGLISH)
		else:
			LocalizationManager.set_language(LocalizationManager.Language.RUSSIAN)
	update_localization()

func _on_volume_changed(value: float, setting_key: String):
	match setting_key:
		"master_volume":
			master_volume = value
			if master_bus_index != -1:
				AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
		"music_volume":
			music_volume = value
			if music_bus_index != -1:
				AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
			# Обновляем громкость в SoundManager
			if SoundManager:
				SoundManager.set_music_volume(value)
	save_settings()

func _on_prev_background():
	if AssetManager:
		AssetManager.previous_background()
		apply_current_background()
		update_background_counter()
		AssetManager.save_asset_settings()

func _on_next_background():
	if AssetManager:
		AssetManager.next_background()
		apply_current_background()
		update_background_counter()
		AssetManager.save_asset_settings()

func _on_prev_music_track():
	if AssetManager:
		AssetManager.previous_music()
		apply_current_music_track()
		update_music_track_counter()
		AssetManager.save_asset_settings()

func _on_next_music_track():
	if AssetManager:
		AssetManager.next_music()
		apply_current_music_track()
		update_music_track_counter()
		AssetManager.save_asset_settings()

func apply_current_background():
	if AssetManager:
		var bg_texture = AssetManager.get_current_background()
		if background and bg_texture:
			background.texture = bg_texture

func apply_current_music_track():
	if AssetManager and SoundManager:
		var music_stream = AssetManager.get_current_music()
		if music_stream:
			# Полная перезагрузка музыки
			if SoundManager.music_player.playing:
				SoundManager.music_player.stop()
			
			SoundManager.music_player.stream = music_stream
			SoundManager.music_player.play()

func update_background_counter():
	if background_label_ref and AssetManager:
		background_label_ref.text = str(AssetManager.current_background_index + 1) + "/" + str(AssetManager.get_background_count())

func update_music_track_counter():
	if music_track_label_ref and AssetManager:
		music_track_label_ref.text = str(AssetManager.current_music_index + 1) + "/" + str(AssetManager.get_music_count())

func update_localization():
	if not LocalizationManager:
		return
	
	if title_label:
		title_label.text = LocalizationManager.get_text("settings")
	
	if back_button:
		back_button.text = LocalizationManager.get_text("menu")
	
	update_copyright_text()
	
	# Пересоздаем настройки с новым языком
	call_deferred("setup_settings_content")

func update_copyright_text():
	if copyright_label and LocalizationManager:
		if LocalizationManager.get_current_language() == LocalizationManager.Language.RUSSIAN:
			copyright_label.text = "© 2025 13.ink - Все права защищены"
		else:
			copyright_label.text = "© 2025 13.ink - All rights reserved"

func _on_back_pressed():
	save_settings()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func save_settings():
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("assets", "current_background", AssetManager.current_background_index if AssetManager else 0)
	config.set_value("assets", "current_music_track", AssetManager.current_music_index if AssetManager else 0)
	
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		current_background = config.get_value("assets", "current_background", 0)
		current_music_track = config.get_value("assets", "current_music_track", 0)
		
		if AssetManager:
			AssetManager.current_background_index = current_background
			AssetManager.current_music_index = current_music_track
		
		if master_bus_index != -1:
			AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))
		if music_bus_index != -1:
			AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
