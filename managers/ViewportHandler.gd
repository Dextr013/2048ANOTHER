extends Node

# ИСПРАВЛЕННЫЙ ViewportHandler с поддержкой iOS Safe Area

signal orientation_changed(is_portrait: bool)
signal viewport_resized(new_size: Vector2)
signal safe_area_changed(safe_rect: Rect2)

var current_size: Vector2
var is_portrait: bool = true
var safe_area_insets: Dictionary = {}

func _ready():
	print("=== ViewportHandler Initialized ===")
	
	# Настраиваем viewport ПЕРЕД блокировкой ориентации
	setup_viewport()
	
	# Получаем начальный размер
	if get_viewport():
		current_size = get_viewport().get_visible_rect().size
		is_portrait = current_size.y > current_size.x
		
		# Подключаемся к изменению размера
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Получаем safe area для iOS
	detect_safe_area()
	
	# Блокировка портретной ориентации на мобильных
	lock_portrait_orientation()
	
	print("ViewportHandler: Initial size: ", current_size)
	print("ViewportHandler: Portrait mode: ", is_portrait)

func setup_viewport():
	"""Правильная настройка viewport для всех платформ"""
	var root = get_tree().root
	
	if OS.has_feature("web"):
		# Веб-платформа
		print("ViewportHandler: Configuring for WEB")
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	elif OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		# Мобильные платформы
		print("ViewportHandler: Configuring for MOBILE")
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		
		# Для iOS - дополнительные настройки
		if OS.has_feature("ios"):
			print("ViewportHandler: iOS specific configuration")
			# Убеждаемся что viewport растягивается правильно
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	else:
		# Десктоп
		print("ViewportHandler: Configuring for DESKTOP")
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func detect_safe_area():
	"""Определение безопасной области для iOS и Android"""
	safe_area_insets = {
		"top": 0,
		"bottom": 0,
		"left": 0,
		"right": 0
	}
	
	if OS.has_feature("ios"):
		# Для iOS используем DisplayServer
		if DisplayServer.has_feature(DisplayServer.FEATURE_SCREEN_CAPTURE):
			# iOS Safe Area API
			var screen_safe_area = DisplayServer.get_display_safe_area()
			if screen_safe_area:
				var screen_size = DisplayServer.screen_get_size()
				
				safe_area_insets["top"] = max(44, screen_safe_area.position.y)
				safe_area_insets["bottom"] = max(34, screen_size.y - screen_safe_area.end.y)
				safe_area_insets["left"] = screen_safe_area.position.x
				safe_area_insets["right"] = screen_size.x - screen_safe_area.end.x
				
				print("ViewportHandler: iOS Safe Area detected: ", safe_area_insets)
		else:
			# Fallback для старых устройств
			safe_area_insets["top"] = 44  # Status bar
			safe_area_insets["bottom"] = 34  # Home indicator
			print("ViewportHandler: iOS Safe Area fallback applied")
	
	elif OS.has_feature("android"):
		# Для Android с вырезами
		safe_area_insets["top"] = 24  # Status bar
		safe_area_insets["bottom"] = 48  # Navigation bar
		print("ViewportHandler: Android Safe Area applied")
	
	elif OS.has_feature("web"):
		# Для веб-платформы через JavaScript
		detect_web_safe_area()

func detect_web_safe_area():
	"""Определение safe area для веб через JavaScript"""
	if not JavaScriptBridge:
		return
	
	var safe_area_code = """
		(function() {
			try {
				// Проверяем CSS переменные safe-area-inset
				var style = getComputedStyle(document.documentElement);
				
				var top = parseInt(style.getPropertyValue('--safe-area-inset-top') || '0') || 0;
				var bottom = parseInt(style.getPropertyValue('--safe-area-inset-bottom') || '0') || 0;
				var left = parseInt(style.getPropertyValue('--safe-area-inset-left') || '0') || 0;
				var right = parseInt(style.getPropertyValue('--safe-area-inset-right') || '0') || 0;
				
				// Если нет CSS переменных, пробуем env()
				if (top === 0 && window.CSS && window.CSS.supports) {
					if (window.CSS.supports('padding-top: env(safe-area-inset-top)')) {
						// Устанавливаем минимальные значения для iOS
						top = 44;
						bottom = 34;
					}
				}
				
				console.log('ViewportHandler: Web Safe Area:', {top, bottom, left, right});
				
				return {
					top: top,
					bottom: bottom,
					left: left,
					right: right
				};
			} catch(e) {
				console.error('ViewportHandler: Error detecting safe area:', e);
				return {top: 0, bottom: 0, left: 0, right: 0};
			}
		})()
	"""
	
	var result = JavaScriptBridge.eval(safe_area_code)
	if result and typeof(result) == TYPE_DICTIONARY:
		safe_area_insets = result
		print("ViewportHandler: Web Safe Area detected: ", safe_area_insets)

func lock_portrait_orientation():
	"""Блокировка портретной ориентации"""
	if OS.has_feature('mobile') or OS.has_feature('android') or OS.has_feature('ios'):
		print("ViewportHandler: Locking portrait orientation")
		
		# Устанавливаем fullscreen режим
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		# Блокируем портретную ориентацию
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		
		print("ViewportHandler: Portrait orientation locked")
	
	elif OS.has_feature("web"):
		# Для веб пытаемся через Screen Orientation API
		lock_web_orientation()

func lock_web_orientation():
	"""Блокировка ориентации через JavaScript для веб"""
	if not JavaScriptBridge:
		return
	
	var lock_code = """
		(function() {
			try {
				console.log('ViewportHandler: Attempting to lock orientation on web');
				
				// Screen Orientation API
				if (screen.orientation && screen.orientation.lock) {
					screen.orientation.lock('portrait').then(function() {
						console.log('ViewportHandler: Orientation locked to portrait');
					}).catch(function(error) {
						console.warn('ViewportHandler: Could not lock orientation:', error);
					});
				} else {
					console.warn('ViewportHandler: Screen Orientation API not available');
				}
				
				// Для iOS Safari добавляем viewport meta
				var viewport = document.querySelector('meta[name="viewport"]');
				if (!viewport) {
					viewport = document.createElement('meta');
					viewport.name = 'viewport';
					document.head.appendChild(viewport);
				}
				
				// Обновляем viewport для правильного отображения
				viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
				
				console.log('ViewportHandler: Viewport meta updated');
				return true;
			} catch(e) {
				console.error('ViewportHandler: Error in lock_web_orientation:', e);
				return false;
			}
		})()
	"""
	
	JavaScriptBridge.eval(lock_code)

func _on_viewport_size_changed():
	if not get_viewport():
		return
	
	var new_size = get_viewport().get_visible_rect().size
	
	if new_size != current_size:
		print("ViewportHandler: Viewport resized from ", current_size, " to ", new_size)
		current_size = new_size
		viewport_resized.emit(new_size)
		
		# Проверяем изменение ориентации
		var new_is_portrait = new_size.y > new_size.x
		if new_is_portrait != is_portrait:
			is_portrait = new_is_portrait
			print("ViewportHandler: Orientation changed to ", "Portrait" if is_portrait else "Landscape")
			orientation_changed.emit(is_portrait)
			
			# Если перешли в альбомный, возвращаем в портретный
			if not is_portrait and (OS.has_feature('mobile') or OS.has_feature('android') or OS.has_feature('ios')):
				print("ViewportHandler: Detected landscape, forcing back to portrait")
				call_deferred("lock_portrait_orientation")
		
		# Обновляем safe area при изменении размера
		detect_safe_area()
		emit_safe_area_changed()

func emit_safe_area_changed():
	var safe_rect = get_safe_area_rect()
	safe_area_changed.emit(safe_rect)

func get_current_size() -> Vector2:
	return current_size

func is_portrait_orientation() -> bool:
	return is_portrait

func is_landscape_orientation() -> bool:
	return not is_portrait

func get_safe_area_rect() -> Rect2:
	"""Возвращает безопасную область с учетом вырезов"""
	if not get_viewport():
		return Rect2()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Базовый отступ
	var margin_top = max(40.0, float(safe_area_insets.get("top", 40)))
	var margin_bottom = max(40.0, float(safe_area_insets.get("bottom", 40)))
	var margin_left = max(20.0, float(safe_area_insets.get("left", 20)))
	var margin_right = max(20.0, float(safe_area_insets.get("right", 20)))
	
	# Для iOS увеличиваем отступы
	if OS.has_feature("ios"):
		margin_top = max(margin_top, 60.0)
		margin_bottom = max(margin_bottom, 50.0)
	
	return Rect2(
		Vector2(margin_left, margin_top),
		viewport_size - Vector2(margin_left + margin_right, margin_top + margin_bottom)
	)

func get_safe_area_margins() -> Dictionary:
	"""Возвращает отступы безопасной зоны"""
	var safe_rect = get_safe_area_rect()
	var viewport_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2.ZERO
	
	return {
		"left": safe_rect.position.x,
		"top": safe_rect.position.y,
		"right": viewport_size.x - safe_rect.end.x,
		"bottom": viewport_size.y - safe_rect.end.y
	}

func get_safe_area_insets() -> Dictionary:
	"""Возвращает сырые insets safe area"""
	return safe_area_insets.duplicate()

# Утилита для проверки что точка внутри safe area
func is_point_in_safe_area(point: Vector2) -> bool:
	var safe_rect = get_safe_area_rect()
	return safe_rect.has_point(point)

# Адаптация позиции в safe area
func adapt_position_to_safe_area(position: Vector2) -> Vector2:
	var safe_rect = get_safe_area_rect()
	return Vector2(
		clamp(position.x, safe_rect.position.x, safe_rect.end.x),
		clamp(position.y, safe_rect.position.y, safe_rect.end.y)
	)
