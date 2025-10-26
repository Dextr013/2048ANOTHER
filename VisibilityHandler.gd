extends Node

# Универсальный обработчик видимости для всех платформ
# Решает проблему с музыкой при сворачивании/переключении вкладок

signal visibility_changed(is_visible: bool)

var is_visible: bool = true
var last_check_time: float = 0.0
const CHECK_INTERVAL: float = 0.5  # Проверка каждые 0.5 секунды

func _ready():
	print("=== VisibilityHandler Initialized ===")
	
	# Подключаем обработчики для всех платформ
	setup_desktop_handlers()
	setup_web_handlers()
	setup_mobile_handlers()

func _process(delta: float):
	# Периодическая проверка для веб-платформы
	if OS.has_feature("web"):
		last_check_time += delta
		if last_check_time >= CHECK_INTERVAL:
			last_check_time = 0.0
			check_web_visibility()

func setup_desktop_handlers():
	"""Обработчики для десктопных платформ"""
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		print("VisibilityHandler: Setting up desktop handlers")
		# Эти уведомления будут приходить автоматически

func setup_web_handlers():
	"""Обработчики для веб-платформы через JavaScript"""
	if OS.has_feature("web") and JavaScriptBridge:
		print("VisibilityHandler: Setting up web handlers")
		
		# Регистрируем слушатели событий видимости
		var setup_code = """
			(function() {
				console.log('VisibilityHandler: Setting up web visibility listeners');
				
				// Обработчик для Page Visibility API
				document.addEventListener('visibilitychange', function() {
					var isVisible = !document.hidden;
					console.log('VisibilityHandler: Visibility changed to', isVisible);
					
					// Отправляем событие в Godot
					if (window.godot_visibility_callback) {
						window.godot_visibility_callback(isVisible);
					}
				});
				
				// Обработчик для focus/blur
				window.addEventListener('blur', function() {
					console.log('VisibilityHandler: Window blur');
					if (window.godot_visibility_callback) {
						window.godot_visibility_callback(false);
					}
				});
				
				window.addEventListener('focus', function() {
					console.log('VisibilityHandler: Window focus');
					if (window.godot_visibility_callback) {
						window.godot_visibility_callback(true);
					}
				});
				
				console.log('VisibilityHandler: Web handlers set up successfully');
				return true;
			})()
		"""
		
		JavaScriptBridge.eval(setup_code)
		
		# Создаем callback для получения событий из JavaScript
		var _callback = JavaScriptBridge.create_callback(_on_web_visibility_changed)
		
		# Регистрируем callback глобально
		var register_callback = """
			window.godot_visibility_callback = arguments[0];
			console.log('VisibilityHandler: Callback registered');
		"""
		JavaScriptBridge.eval(register_callback, false)

func setup_mobile_handlers():
	"""Обработчики для мобильных платформ"""
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		print("VisibilityHandler: Setting up mobile handlers")
		# Мобильные платформы будут использовать NOTIFICATION_APPLICATION_*

func check_web_visibility():
	"""Проверка видимости для веб-платформы"""
	if not JavaScriptBridge:
		return
	
	var check_code = """
		(function() {
			return !document.hidden;
		})()
	"""
	
	var new_visibility = JavaScriptBridge.eval(check_code)
	
	if new_visibility != is_visible:
		is_visible = new_visibility
		_handle_visibility_change(is_visible)

func _on_web_visibility_changed(args):
	"""Callback из JavaScript"""
	if args.size() > 0:
		var new_visibility = args[0]
		if new_visibility != is_visible:
			is_visible = new_visibility
			_handle_visibility_change(is_visible)

func _notification(what):
	match what:
		# Десктопные уведомления
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			print("VisibilityHandler: Window focus in")
			_handle_visibility_change(true)
		
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			print("VisibilityHandler: Window focus out")
			_handle_visibility_change(false)
		
		# Мобильные уведомления
		NOTIFICATION_APPLICATION_FOCUS_IN:
			print("VisibilityHandler: Application focus in")
			_handle_visibility_change(true)
		
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			print("VisibilityHandler: Application focus out")
			_handle_visibility_change(false)
		
		NOTIFICATION_APPLICATION_PAUSED:
			print("VisibilityHandler: Application paused")
			_handle_visibility_change(false)
		
		NOTIFICATION_APPLICATION_RESUMED:
			print("VisibilityHandler: Application resumed")
			_handle_visibility_change(true)
		
		# Веб-специфичные
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("VisibilityHandler: Close request")
			_handle_visibility_change(false)

# В метод _handle_visibility_change добавляем:
func _handle_visibility_change(visible: bool):
	if is_visible == visible:
		return
	
	is_visible = visible
	print("VisibilityHandler: Visibility changed to ", "VISIBLE" if visible else "HIDDEN")
	
	# Управление музыкой
	if SoundManager:
		if visible:
			print("VisibilityHandler: Resuming music")
			SoundManager.resume_music()
		else:
			print("VisibilityHandler: Pausing music")
			SoundManager.pause_music()
	
	# Уведомляем Poki о паузе/возобновлении игры - НОВАЯ ФУНКЦИОНАЛЬНОСТЬ
	if has_node("/root/GameReadyAPI"):
		var game_ready = get_node("/root/GameReadyAPI")
		if game_ready and game_ready.has_method("gameplay_stop") and game_ready.has_method("gameplay_start"):
			if visible:
				game_ready.gameplay_start()
			else:
				game_ready.gameplay_stop()
	
	# Отправляем сигнал
	visibility_changed.emit(visible)

func get_is_visible() -> bool:
	return is_visible

func _exit_tree():
	# Очистка для веб-платформы
	if OS.has_feature("web") and JavaScriptBridge:
		var cleanup_code = """
			if (window.godot_visibility_callback) {
				console.log('VisibilityHandler: Cleaning up callback');
				window.godot_visibility_callback = null;
			}
		"""
		JavaScriptBridge.eval(cleanup_code)
