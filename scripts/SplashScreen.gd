class_name SplashScreen
extends Control

var splash_texture_rect: TextureRect
var locale_detector: BrowserLocaleDetector
var copyright_label: Label

signal splash_finished

func _ready():
	setup_locale_detection()
	setup_splash_screen()
	show_splash()

func setup_locale_detection():
	# Create and add the browser locale detector
	locale_detector = BrowserLocaleDetector.new()
	add_child(locale_detector)
	
	# Apply detected locale immediately
	await get_tree().process_frame
	locale_detector.apply_detected_locale()
	
	print("Splash: Locale detection info: ", locale_detector.get_debug_info())

func setup_splash_screen():
	# Set up full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create texture rect for splash image
	splash_texture_rect = TextureRect.new()
	add_child(splash_texture_rect)
	splash_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	splash_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Set background color
	var background = ColorRect.new()
	add_child(background)
	move_child(background, 0)  # Move to back
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.05, 0.1, 1.0)  # Dark cyberpunk background

func show_splash():
	# Check if splash has been shown before
	if has_shown_splash():
		skip_splash()
		return
	
	# Load localized splash screen
	var splash_texture = load_localized_splash_texture()
	if splash_texture:
		splash_texture_rect.texture = splash_texture
	
	# Add title text with localized content
	add_title_text()
	
	# Add copyright label
	add_copyright_label()
	
	# Fade in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Auto-skip after 3 seconds or on input
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_on_splash_timeout)
	timer.start()
	
	# Mark splash as shown
	mark_splash_shown()

func load_localized_splash_texture() -> Texture2D:
	if not locale_detector:
		return load("res://assets/splash.png")
	
	# Try to load localized splash screen
	var localized_path = "res://assets/splash/splash" + locale_detector.get_splash_screen_suffix() + ".png"
	print("Trying to load splash from: ", localized_path)
	
	var localized_texture = load(localized_path)
	if localized_texture:
		return localized_texture
	
	# Fallback to default splash (English version)
	var default_splash = load("res://assets/splash/splash_en.png")
	if default_splash:
		print("Using default splash texture")
		return default_splash
	
	print("No splash textures found")
	return null

func add_title_text():
	var title_label = Label.new()
	add_child(title_label)
	pass
	# Set localized text
	if locale_detector and locale_detector.is_russian_locale():
		title_label.text = ""
	else:
		title_label.text = ""
	
	title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Cyan
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func add_copyright_label():
	copyright_label = Label.new()
	add_child(copyright_label)
	
	if locale_detector and locale_detector.is_russian_locale():
		copyright_label.text = "© 2025 13.ink - Все права защищены"
	else:
		copyright_label.text = "© 2025 13.ink - All rights reserved"
		
	copyright_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	copyright_label.position.y -= 30
	copyright_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copyright_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
	copyright_label.add_theme_font_size_override("font_size", 64)
	
	# Убрано применение кастомного шрифта

func _input(event):
	# Skip splash on any input
	if event is InputEventKey and event.pressed:
		skip_splash()
	elif event is InputEventMouseButton and event.pressed:
		skip_splash()
	elif event is InputEventScreenTouch and event.pressed:
		skip_splash()

func _on_splash_timeout():
	skip_splash()

func skip_splash():
	# Fade out and finish
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(finish_splash)

func finish_splash():
	splash_finished.emit()
	queue_free()

func has_shown_splash() -> bool:
	# Check if splash was shown in this session
	var config = ConfigFile.new()
	var err = config.load("user://splash_state.cfg")
	
	if err == OK:
		var last_shown = config.get_value("splash", "last_shown", "")
		var today = Time.get_date_string_from_system()
		return last_shown == today
	
	return false

func mark_splash_shown():
	# Mark splash as shown for today
	var config = ConfigFile.new()
	var today = Time.get_date_string_from_system()
	config.set_value("splash", "last_shown", today)
	config.save("user://splash_state.cfg")

# Static function to check if splash should be shown
static func should_show_splash() -> bool:
	var config = ConfigFile.new()
	var err = config.load("user://splash_state.cfg")
	
	if err == OK:
		var last_shown = config.get_value("splash", "last_shown", "")
		var today = Time.get_date_string_from_system()
		return last_shown != today
	
	return true  # Show splash if no record exists
