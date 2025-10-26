extends Control

@onready var time_label: Label = $TimeLabel
@onready var background: ColorRect = $Background

var time_remaining: float = 180.0
var is_warning: bool = false

func _ready():
	setup_visual()
	update_display()

func setup_visual():
	# Настройка фона
	if background:
		background.color = Color(0.1, 0.1, 0.2, 0.9)
	
	# Настройка метки
	if time_label:
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_label.add_theme_font_size_override("font_size", 36)
		time_label.add_theme_color_override("font_color", Color.WHITE)

func update_time(seconds: float):
	time_remaining = max(0.0, seconds)
	update_display()
	
	# Предупреждение при малом времени
	if time_remaining <= 30.0 and time_remaining > 0.0:
		if not is_warning:
			is_warning = true
			start_warning_animation()
	elif is_warning and time_remaining > 30.0:
		is_warning = false
		stop_warning_animation()

func update_display():
	if not time_label:
		return
	
	# ИСПРАВЛЕНИЕ: Правильное форматирование времени
	var total_seconds = int(time_remaining)
	var minutes = total_seconds / 60.0
	var seconds = total_seconds % 60
	
	# Локализация префикса
	var time_prefix = ""
	if LocalizationManager:
		var current_lang = LocalizationManager.get_current_language()
		if current_lang == LocalizationManager.Language.RUSSIAN:
			time_prefix = "Время: "
		else:
			time_prefix = "Time: "
	else:
		time_prefix = "Time: "
	
	# Форматируем с ведущими нулями
	time_label.text = "%s%02d:%02d" % [time_prefix, minutes, seconds]
	
	# Цвет в зависимости от оставшегося времени
	if time_remaining <= 10.0:
		time_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining <= 30.0:
		time_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		time_label.add_theme_color_override("font_color", Color.WHITE)

func start_warning_animation():
	# Пульсация при малом времени
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(time_label, "modulate:a", 0.5, 0.5)
	tween.tween_property(time_label, "modulate:a", 1.0, 0.5)

func stop_warning_animation():
	# Останавливаем все анимации
	for tween in get_tree().get_nodes_in_group("tweens"):
		if tween.is_valid():
			tween.kill()
	
	# Возвращаем нормальную прозрачность
	if time_label:
		time_label.modulate.a = 1.0

func get_time_remaining() -> float:
	return time_remaining

func reset_time(seconds: float):
	time_remaining = seconds
	is_warning = false
	stop_warning_animation()
	update_display()

func update_localization():
	"""Обновление при смене языка"""
	update_display()
