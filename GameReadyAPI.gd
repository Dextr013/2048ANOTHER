extends Node

# ИНТЕГРАЦИЯ POKI SDK для Web платформы

var _is_initialized: bool = false
var _ad_available: bool = false
var _is_initializing: bool = false

# Свойства платформы
var is_web_platform: bool = false
var is_mock_mode: bool = true

# Сигналы
signal sdk_initialized(success: bool)
signal interstitial_ad_shown(success: bool)
signal rewarded_ad_shown(success: bool, reward_granted: bool)

var _initialization_attempts: int = 0
const MAX_INIT_ATTEMPTS: int = 3

func _ready():
	print("=== Poki SDK Initializing ===")
	
	is_web_platform = OS.has_feature("web")
	is_mock_mode = not is_web_platform
	
	if is_web_platform:
		print("Web platform detected - initializing Poki SDK")
		call_deferred("init_poki_sdk")
	else:
		print("Non-web platform - using mock mode")
		_is_initialized = true
		_ad_available = true
		call_deferred("emit_initialization_signals")

func emit_initialization_signals():
	if not _is_initialized:
		_is_initialized = true
	sdk_initialized.emit(true)

func init_poki_sdk():
	if _is_initializing:
		print("SDK initialization already in progress")
		return
	
	_is_initializing = true
	_initialization_attempts += 1
	
	print("Initialization attempt ", _initialization_attempts, " of ", MAX_INIT_ATTEMPTS)
	
	if not JavaScriptBridge:
		print("ERROR: JavaScriptBridge not available!")
		handle_initialization_failure()
		return
	
	print("Checking Poki SDK availability...")
	
	var check_sdk_code = """
		(typeof PokiSDK !== 'undefined')
	"""
	
	var sdk_available = JavaScriptBridge.eval(check_sdk_code)
	print("Poki SDK available: ", sdk_available)
	
	if not sdk_available:
		print("Poki SDK not found - using mock mode")
		handle_initialization_failure()
		return
	
	print("Starting Poki SDK initialization...")
	
	# Инициализация Poki SDK
	var init_code = """
		(function() {
			try {
				console.log('Poki: Initializing SDK');
				
				// Инициализация Poki SDK
				if (PokiSDK.init) {
					PokiSDK.init()
						.then(() => {
							console.log('Poki: SDK initialized successfully');
							window._poki_initialized = true;
							
							// Настройка обработчиков рекламы
							if (PokiSDK.setDebug) {
								PokiSDK.setDebug(true);
							}
							
							// Обработчики паузы/возобновления игры
							if (PokiSDK.gameplayStart) {
								PokiSDK.gameplayStart();
							}
						})
						.catch((error) => {
							console.error('Poki: Init error:', error);
							window._poki_initialized = false;
						});
				}
				
				return true;
			} catch(error) {
				console.error('Poki: Exception in init:', error);
				return false;
			}
		})()
	"""
	
	JavaScriptBridge.eval(init_code, false)
	
	# Ждем результата
	await get_tree().create_timer(2.0).timeout
	
	var check_result = "window._poki_initialized === true"
	var init_success = JavaScriptBridge.eval(check_result)
	
	if init_success:
		print("Poki: SDK initialized successfully")
		_is_initialized = true
		_ad_available = true
		_is_initializing = false
		sdk_initialized.emit(true)
		setup_poki_listeners()
	else:
		print("Poki: SDK initialization failed")
		if _initialization_attempts < MAX_INIT_ATTEMPTS:
			print("Retrying initialization...")
			_is_initializing = false
			await get_tree().create_timer(1.0).timeout
			init_poki_sdk()
		else:
			handle_initialization_failure()

func handle_initialization_failure():
	print("Poki: SDK initialization failed after ", _initialization_attempts, " attempts")
	_is_initialized = true
	_is_initializing = false
	sdk_initialized.emit(false)

func setup_poki_listeners():
	"""Настройка обработчиков событий Poki"""
	if not JavaScriptBridge:
		return
	
	var setup_code = """
		(function() {
			try {
				console.log('Poki: Setting up event listeners');
				
				// Обработчик паузы игры
				if (PokiSDK.gameplayStop) {
					// Будем вызывать вручную из Godot
				}
				
				// Обработчик счастливых моментов
				if (PokiSDK.happyTime) {
					// Будем вызывать вручную из Godot
				}
				
				console.log('Poki: Event listeners set up');
				return true;
			} catch(error) {
				console.error('Poki: Error setting up listeners:', error);
				return false;
			}
		})()
	"""
	
	JavaScriptBridge.eval(setup_code)

func is_initialized() -> bool:
	return _is_initialized

func is_ad_available() -> bool:
	if is_mock_mode:
		return true
	return _ad_available

func show_interstitial_ad():
	print("Poki: Showing interstitial ad")
	
	if not is_ad_available():
		print("Poki: Ad not available")
		interstitial_ad_shown.emit(false)
		return
	
	if is_mock_mode:
		print("Poki: [MOCK] Interstitial ad shown")
		await get_tree().create_timer(0.5).timeout
		interstitial_ad_shown.emit(true)
		return
	
	if not JavaScriptBridge:
		print("Poki: JavaScriptBridge not available")
		interstitial_ad_shown.emit(false)
		return
	
	var show_ad_code = """
		(function() {
			try {
				if (typeof PokiSDK !== 'undefined' && PokiSDK.showInterstitial) {
					console.log('Poki: Showing interstitial');
					return PokiSDK.showInterstitial()
						.then(() => {
							console.log('Poki: Interstitial completed');
							return true;
						})
						.catch((error) => {
							console.error('Poki: Interstitial error:', error);
							return false;
						});
				} else {
					console.error('Poki: Interstitial not available');
					return Promise.resolve(false);
				}
			} catch(error) {
				console.error('Poki: Exception in showInterstitial:', error);
				return Promise.resolve(false);
			}
		})()
	"""
	
	var result = JavaScriptBridge.eval(show_ad_code, true)
	
	if result and result is JavaScriptObject:
		var callback = JavaScriptBridge.create_callback(func(args):
			var success = args.size() > 0 and args[0]
			print("Poki: Interstitial ad completed, success: ", success)
			interstitial_ad_shown.emit(success)
		)
		
		result.then(callback)
	else:
		print("Poki: Failed to execute interstitial ad code")
		interstitial_ad_shown.emit(false)

func show_rewarded_ad() -> bool:
	print("Poki: Showing rewarded ad")
	
	if not is_ad_available():
		print("Poki: Ad not available")
		rewarded_ad_shown.emit(false, false)
		return false
	
	if is_mock_mode:
		print("Poki: [MOCK] Rewarded ad shown")
		await get_tree().create_timer(1.0).timeout
		rewarded_ad_shown.emit(true, true)
		return true
	
	if not JavaScriptBridge:
		print("Poki: JavaScriptBridge not available")
		rewarded_ad_shown.emit(false, false)
		return false
	
	var show_ad_code = """
		(function() {
			try {
				if (typeof PokiSDK !== 'undefined' && PokiSDK.rewardedBreak) {
					console.log('Poki: Showing rewarded ad');
					return PokiSDK.rewardedBreak()
						.then((success) => {
							console.log('Poki: Rewarded ad completed, success:', success);
							return success;
						})
						.catch((error) => {
							console.error('Poki: Rewarded ad error:', error);
							return false;
						});
				} else {
					console.error('Poki: Rewarded ad not available');
					return Promise.resolve(false);
				}
			} catch(error) {
				console.error('Poki: Exception in rewardedBreak:', error);
				return Promise.resolve(false);
			}
		})()
	"""
	
	var result = JavaScriptBridge.eval(show_ad_code, true)
	
	if result and result is JavaScriptObject:
		var callback = JavaScriptBridge.create_callback(func(args):
			var success = args.size() > 0 and args[0]
			print("Poki: Rewarded ad completed, success: ", success)
			rewarded_ad_shown.emit(success, success)
		)
		
		result.then(callback)
		return true
	else:
		print("Poki: Failed to execute rewarded ad code")
		rewarded_ad_shown.emit(false, false)
		return false

func gameplay_start():
	"""Уведомление о начале игрового процесса"""
	if is_mock_mode or not _is_initialized:
		return
	
	if JavaScriptBridge:
		var code = """
			(function() {
				if (typeof PokiSDK !== 'undefined' && PokiSDK.gameplayStart) {
					PokiSDK.gameplayStart();
					console.log('Poki: Gameplay started');
				}
			})()
		"""
		JavaScriptBridge.eval(code)

func gameplay_stop():
	"""Уведомление о завершении игрового процесса"""
	if is_mock_mode or not _is_initialized:
		return
	
	if JavaScriptBridge:
		var code = """
			(function() {
				if (typeof PokiSDK !== 'undefined' && PokiSDK.gameplayStop) {
					PokiSDK.gameplayStop();
					console.log('Poki: Gameplay stopped');
				}
			})()
		"""
		JavaScriptBridge.eval(code)

func happy_time(seconds: float):
	"""Активация счастливого момента (увеличивает монетизацию)"""
	if is_mock_mode or not _is_initialized:
		return
	
	if JavaScriptBridge:
		var code = """
			(function(seconds) {
				if (typeof PokiSDK !== 'undefined' && PokiSDK.happyTime) {
					PokiSDK.happyTime(seconds);
					console.log('Poki: Happy time activated for', seconds, 'seconds');
				}
			})(%f)
		""" % seconds
		JavaScriptBridge.eval(code)

func send_analytics_event(event_name: String, params: Dictionary = {}):
	"""Отправка аналитики (Poki автоматически собирает аналитику)"""
	print("Poki: Analytics event: ", event_name)
	
	if is_mock_mode:
		print("Poki: [MOCK] Analytics sent: ", event_name)
		return
	
	# Poki автоматически собирает аналитику, но можно отправлять кастомные события
	if JavaScriptBridge:
		var params_json = JSON.stringify(params)
		var safe_event_name = event_name.replace("'", "\\'")
		
		var analytics_code = """
			(function() {
				try {
					console.log('Poki: Custom event:', '%s', %s);
					
					// Poki автоматически собирает аналитику
					// Можно добавить кастомную логику если нужно
					
					return true;
				} catch(error) {
					console.error('Poki: Analytics error:', error);
					return false;
				}
			})()
		""" % [safe_event_name, params_json]
		
		JavaScriptBridge.eval(analytics_code)

func get_player_data() -> Dictionary:
	"""Получение данных игрока"""
	if is_mock_mode:
		return {
			"name": "Test Player",
			"uniqueID": "mock_player_123",
			"isAuthorized": true
		}
	
	# Poki не предоставляет данные игрока напрямую
	return {
		"name": "Player",
		"isAuthorized": false
	}

func get_mode() -> String:
	return "MOCK (Development)" if is_mock_mode else "WEB (Poki)"

func is_web() -> bool:
	return is_web_platform

func is_mock() -> bool:
	return is_mock_mode

func get_status() -> Dictionary:
	return {
		"initialized": _is_initialized,
		"ad_available": _ad_available,
		"is_initializing": _is_initializing,
		"is_web": is_web_platform,
		"is_mock": is_mock_mode,
		"initialization_attempts": _initialization_attempts
	}

func _exit_tree():
	print("Poki: Exiting tree - cleaning up")
	gameplay_stop()
