extends Panel

@onready var vbox: VBoxContainer = $VBox
@onready var title_label: Label = $VBox/TitleLabel
@onready var watch_ad_button: Button = $VBox/WatchAdButton
@onready var ad_description: Label = $VBox/AdDescription
@onready var menu_button: Button = $VBox/MenuButton
@onready var restart_button: Button = $VBox/RestartButton
@onready var settings_button: Button = $VBox/SettingsButton

signal watch_ad_pressed
signal menu_pressed
signal restart_pressed
signal settings_pressed

func _ready():
	# Устанавливаем якоря для центрирования с безопасными отступами
	set_anchors_preset(Control.PRESET_CENTER)
	
	# Connect signals
	if watch_ad_button:
		if not watch_ad_button.pressed.is_connected(_on_watch_ad_pressed):
			watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	
	if menu_button:
		if not menu_button.pressed.is_connected(_on_menu_pressed):
			menu_button.pressed.connect(_on_menu_pressed)
	
	if restart_button:
		if not restart_button.pressed.is_connected(_on_restart_pressed):
			restart_button.pressed.connect(_on_restart_pressed)
	
	if settings_button:
		if not settings_button.pressed.is_connected(_on_settings_pressed):
			settings_button.pressed.connect(_on_settings_pressed)
	
	# Настройка VBox
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 15)
	
	# Apply styling and localization
	apply_styling()
	update_localization()
	
	# Update panel size for current viewport
	call_deferred("update_panel_size")
	
	# Подключаем обновление при изменении размера окна
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_panel_size()

func _on_viewport_size_changed():
	update_panel_size()

func apply_styling():
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1.0, 0.0, 0.0, 0.6)
	add_theme_stylebox_override("panel", panel_style)
	
	# Style title
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style buttons
	for button in [watch_ad_button, menu_button, restart_button, settings_button]:
		if button:
			button.add_theme_font_size_override("font_size", 28)
			button.add_theme_color_override("font_color", Color.WHITE)
			button.focus_mode = Control.FOCUS_NONE
			
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
	
	# Style description
	if ad_description:
		ad_description.add_theme_font_size_override("font_size", 20)
		ad_description.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		ad_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ad_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func update_localization():
	if LocalizationManager:
		if title_label:
			title_label.text = LocalizationManager.get_text("game_over")
		if watch_ad_button:
			watch_ad_button.text = LocalizationManager.get_text("watch_ad")
		if ad_description:
			ad_description.text = LocalizationManager.get_text("watch_ad_to_continue")
		if menu_button:
			menu_button.text = LocalizationManager.get_text("menu")
		if restart_button:
			restart_button.text = LocalizationManager.get_text("restart")
		if settings_button:
			settings_button.text = LocalizationManager.get_text("settings")
	else:
		# Fallback to English
		if title_label:
			title_label.text = "GAME OVER"
		if watch_ad_button:
			watch_ad_button.text = "WATCH AD"
		if ad_description:
			ad_description.text = "Watch ad to continue?"
		if menu_button:
			menu_button.text = "MENU"
		if restart_button:
			restart_button.text = "RESTART"
		if settings_button:
			settings_button.text = "SETTINGS"

func show_panel():
	visible = true
	update_panel_size()
	_center_panel()
	
	# Pause music when showing Game Over panel
	if SoundManager:
		SoundManager.force_pause_music()

func hide_panel():
	visible = false
	# Resume music when hiding Game Over panel
	if SoundManager:
		SoundManager.force_resume_music()

func _center_panel():
	var _viewport_size = get_viewport_rect().size
	
	# Центрируем с учетом безопасных зон
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	
	offset_left = -size.x / 2.0
	offset_top = -size.y / 2.0
	offset_right = size.x / 2.0
	offset_bottom = size.y / 2.0

func update_panel_size():
	var viewport_size = get_viewport_rect().size
	
	# Определяем, мобильное ли устройство
	var is_mobile = OS.has_feature('mobile') or OS.has_feature('android') or OS.has_feature('ios')
	var is_portrait = viewport_size.y > viewport_size.x
	
	# ИСПРАВЛЕНИЕ: Адаптивные размеры с безопасными отступами
	var panel_width: float
	var panel_height: float
	var safe_margin = 20  # Безопасный отступ от краев экрана
	
	if is_mobile:
		if is_portrait:
			# Портретная ориентация - уменьшаем размер панели
			panel_width = viewport_size.x * 0.85
			panel_height = viewport_size.y * 0.65
		else:
			# Альбомная ориентация
			panel_width = viewport_size.x * 0.75
			panel_height = viewport_size.y * 0.80
	else:
		panel_width = viewport_size.x * 0.70
		panel_height = viewport_size.y * 0.55
	
	# КРИТИЧЕСКИ ВАЖНО: Убедитесь что панель НЕ БОЛЬШЕ доступного пространства
	panel_width = min(panel_width, viewport_size.x - safe_margin * 2)
	panel_height = min(panel_height, viewport_size.y - safe_margin * 2)
	
	# Ограничиваем размеры
	panel_width = clamp(panel_width, 260, 650)
	panel_height = clamp(panel_height, 280, 550)
	
	# Устанавливаем размер
	custom_minimum_size = Vector2(panel_width, panel_height)
	size = Vector2(panel_width, panel_height)
	
	# Адаптивные размеры шрифтов
	var base_size = min(viewport_size.x, viewport_size.y) * 0.025
	base_size = clamp(base_size, 12, 36)
	
	if title_label:
		var title_size = int(base_size * 1.8)
		title_size = clamp(title_size, 24, 52)
		title_label.add_theme_font_size_override("font_size", title_size)
	
	if ad_description:
		var desc_size = int(base_size * 0.9)
		desc_size = clamp(desc_size, 14, 24)
		ad_description.add_theme_font_size_override("font_size", desc_size)
	
	for button in [watch_ad_button, menu_button, restart_button, settings_button]:
		if button:
			var button_size = int(base_size * 1.1)
			button_size = clamp(button_size, 16, 32)
			button.add_theme_font_size_override("font_size", button_size)
			
			# Адаптивная высота кнопок
			var button_height = viewport_size.y * 0.06
			button_height = clamp(button_height, 40, 65)
			button.custom_minimum_size.y = button_height
			
			# Адаптивная ширина кнопок
			var button_width = panel_width * 0.75
			button.custom_minimum_size.x = button_width
	
	# Обновляем отступы VBox
	if vbox:
		var margin = panel_width * 0.06
		margin = clamp(margin, 12, 30)
		vbox.add_theme_constant_override("margin_left", margin)
		vbox.add_theme_constant_override("margin_right", margin)
		vbox.add_theme_constant_override("margin_top", margin)
		vbox.add_theme_constant_override("margin_bottom", margin)
		
		var separation = panel_height * 0.025
		separation = clamp(separation, 8, 20)
		vbox.add_theme_constant_override("separation", separation)
	
	# Центрируем после изменения размера
	call_deferred("_center_panel")

func _on_watch_ad_pressed():
	watch_ad_pressed.emit()

func _on_menu_pressed():
	menu_pressed.emit()

func _on_restart_pressed():
	restart_pressed.emit()

func _on_settings_pressed():
	settings_pressed.emit()
