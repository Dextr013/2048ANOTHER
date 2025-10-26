class_name GameTile
extends Control

var background: TextureRect
var label: Label

var value: int = 0
var grid_position: Vector2i
var is_moving: bool = false
var current_tween: Tween = null

# Simplified, elegant color palette
var tile_colors = {
	0: Color(0.95, 0.95, 0.95, 0.3),
	2: Color(0.93, 0.89, 0.85, 1.0),
	4: Color(0.93, 0.87, 0.78, 1.0),  
	8: Color(0.95, 0.69, 0.47, 1.0),
	16: Color(0.96, 0.58, 0.39, 1.0),
	32: Color(0.96, 0.49, 0.37, 1.0),
	64: Color(0.96, 0.37, 0.23, 1.0),
	128: Color(0.93, 0.81, 0.45, 1.0),
	256: Color(0.93, 0.80, 0.38, 1.0),
	512: Color(0.93, 0.78, 0.31, 1.0),
	1024: Color(0.93, 0.76, 0.25, 1.0),
	2048: Color(0.93, 0.73, 0.18, 1.0),
	-1: Color(0.2, 0.2, 0.2, 1.0)
}

# Text colors for better readability
var text_colors = {
	0: Color.TRANSPARENT,
	2: Color(0.47, 0.43, 0.39, 1.0),
	4: Color(0.47, 0.43, 0.39, 1.0),
	8: Color.WHITE,
	16: Color.WHITE,
	32: Color.WHITE,
	64: Color.WHITE,
	128: Color.WHITE,
	256: Color.WHITE,
	512: Color.WHITE,
	1024: Color.WHITE,
	2048: Color.WHITE,
	-1: Color.WHITE
}

func _ready():
	# Create UI elements if they don't exist
	if not background:
		background = TextureRect.new()
		add_child(background)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if not label:
		label = Label.new()
		add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set up tile appearance with adaptive font size
	var base_font_size = 56
	label.add_theme_font_size_override("font_size", base_font_size)

# ДОБАВЛЕННЫЙ МЕТОД: устанавливает позицию тайла в сетке
func set_grid_position(pos: Vector2i):
	grid_position = pos
	# Можно добавить дополнительную логику при необходимости

func set_value(new_value: int, instant: bool = false):
	var old_value = value
	value = new_value
	
	update_appearance()
	
	if instant:
		# Для немедленного обновления без анимации
		scale = Vector2.ONE
		modulate.a = 1.0
	elif old_value == 0 and new_value > 0:
		animate_spawn()
	elif old_value > 0 and new_value > old_value:
		animate_merge()
	elif new_value == -1:  # Obstacle spawn
		animate_obstacle_spawn()

func update_appearance():
	if value == 0:
		label.text = ""
		background.texture = null
		background.modulate = tile_colors.get(0, Color.GRAY)
		modulate.a = 0.5
	elif value == -1:  # Obstacle
		label.text = ""
		# Load obstacle texture
		var obstacle_texture = load("res://assets/graphics/tiles/Block.png")
		if obstacle_texture:
			background.texture = obstacle_texture
			background.modulate = Color.WHITE
		else:
			# Fallback to colored square if texture not found
			background.texture = null
			background.modulate = tile_colors.get(-1, Color.BLACK)
		modulate.a = 1.0
	else:
		# Сначала пытаемся загрузить спрайт из AssetManager
		if AssetManager:
			var tile_texture = AssetManager.get_tile_texture(value)
			if tile_texture:
				background.texture = tile_texture
				background.modulate = Color.WHITE
				label.text = ""  # НЕ показываем цифры поверх пользовательских ассетов
			else:
				# Fallback на цветной фон с цифрами
				background.texture = null
				background.modulate = tile_colors.get(value, Color.WHITE)
				label.text = str(value)
		else:
			# Fallback на цветной фон с цифрами если нет AssetManager
			background.texture = null
			background.modulate = tile_colors.get(value, Color.WHITE)
			label.text = str(value)
		
		modulate.a = 1.0
	
	# Настройка текста только если есть текст
	if label.text != "":
		var font_size = 40
		if value >= 1000:
			font_size = 32
		elif value >= 100:
			font_size = 36
		
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", text_colors.get(value, Color.WHITE))

func animate_spawn():
	# Безопасная остановка
	stop_all_animations()
	
	# Проверка валидности узла
	if not is_inside_tree():
		return
	
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	
	current_tween = create_tween()
	if not current_tween:
		return
	
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	current_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	current_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func animate_merge():
	stop_all_animations()
	
	if not is_inside_tree():
		return
	
	current_tween = create_tween()
	if not current_tween:
		return
	
	current_tween.set_parallel(false)
	current_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	current_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	current_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func animate_obstacle_spawn():
	stop_all_animations()
	
	if not is_inside_tree():
		return
	
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	
	current_tween = create_tween()
	if not current_tween:
		return
	
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	current_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	current_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func animate_move_to(target_position: Vector2, duration: float = 0.15):
	stop_all_animations()
	
	if not is_inside_tree():
		return
	
	is_moving = true
	
	current_tween = create_tween()
	if not current_tween:
		is_moving = false
		return
	
	current_tween.tween_property(self, "position", target_position, duration)
	current_tween.finished.connect(_on_move_finished, CONNECT_ONE_SHOT)

func _on_tween_finished():
	current_tween = null

func _on_move_finished():
	is_moving = false
	current_tween = null

func stop_all_animations():
	if current_tween:
		if current_tween.is_valid():
			current_tween.kill()
		current_tween = null
	
	# Сброс свойств только если узел в дереве
	if is_inside_tree():
		scale = Vector2.ONE
		rotation = 0
		modulate.a = 1.0 if value > 0 else 0.5

func _exit_tree():
	# Критично: останавливаем все анимации при удалении
	stop_all_animations()
