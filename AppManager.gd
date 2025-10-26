extends Node

# Глобальный менеджер для инициализации всех систем

var localization_manager: LocalizationManager
var asset_manager: AssetManager
var save_manager: SaveManager
var sound_manager: SoundManager
var game_mode_manager
var viewport_handler: ViewportHandler
var game_ready_api = null
var leaderboard_manager: LeaderboardManager

var _all_managers_ready: bool = false
var _initialization_complete: bool = false
var _game_ready_sent: bool = false  # НОВЫЙ флаг

signal all_managers_initialized()
signal game_fully_ready()  # НОВЫЙ сигнал - когда ВСЁ готово

func _ready():
	print("=== AppManager Initializing ===")
	await get_tree().process_frame
	call_deferred("initialize_all_managers")

func initialize_all_managers():
	print("Initializing all managers...")
	
	initialize_localization_manager()
	initialize_asset_manager() 
	initialize_save_manager()
	initialize_sound_manager()
	initialize_game_mode_manager()
	initialize_viewport_handler()
	await initialize_game_ready_api()
	initialize_leaderboard_manager()
	
	check_initialization_complete()

func initialize_localization_manager():
	if has_node("/root/LocalizationManager"):
		localization_manager = get_node("/root/LocalizationManager")
		print("✓ LocalizationManager initialized")
	else:
		print("✗ LocalizationManager not found")

func initialize_asset_manager():
	if has_node("/root/AssetManager"):
		asset_manager = get_node("/root/AssetManager")
		
		if asset_manager.has_method("are_critical_assets_loaded"):
			if not asset_manager.are_critical_assets_loaded():
				print("Waiting for critical assets...")
				var timeout = 0.0
				while not asset_manager.are_critical_assets_loaded() and timeout < 2.0:
					await get_tree().create_timer(0.1).timeout
					timeout += 0.1
		
		print("✓ AssetManager initialized")
	else:
		print("✗ AssetManager not found")

func initialize_save_manager():
	if has_node("/root/SaveManager"):
		save_manager = get_node("/root/SaveManager")
		
		if save_manager.has_method("load_game"):
			await get_tree().process_frame
		
		print("✓ SaveManager initialized")
	else:
		print("✗ SaveManager not found")

func initialize_sound_manager():
	if has_node("/root/SoundManager"):
		sound_manager = get_node("/root/SoundManager")
		
		if sound_manager.has_method("is_initialized"):
			var timeout = 0.0
			while not sound_manager.is_initialized() and timeout < 1.0:
				await get_tree().create_timer(0.1).timeout
				timeout += 0.1
		
		print("✓ SoundManager initialized")
	else:
		print("✗ SoundManager not found")

func initialize_game_mode_manager():
	game_mode_manager = null
	GameModeManager.load_selected_mode()
	var current_mode = GameModeManager.get_current_mode()
	var mode_name = GameModeManager.get_mode_name(current_mode)
	print("✓ GameModeManager initialized - Mode: ", mode_name)

func initialize_viewport_handler():
	if has_node("/root/ViewportHandler"):
		viewport_handler = get_node("/root/ViewportHandler")
		print("✓ ViewportHandler initialized")
	else:
		print("✗ ViewportHandler not found")

func initialize_game_ready_api():
	game_ready_api = await find_game_ready_api()
	
	if game_ready_api:
		print("✓ GameReady API initialized")
		
		if game_ready_api.has_method("is_initialized"):
			if not game_ready_api.is_initialized():
				print("Waiting for GameReady API initialization...")
				var timeout = 0.0
				while not game_ready_api.is_initialized() and timeout < 3.0:
					await get_tree().create_timer(0.1).timeout
					timeout += 0.1
				
				if game_ready_api.is_initialized():
					print("GameReady API initialization completed")
				else:
					print("GameReady API initialization timeout")
	else:
		print("✗ WARNING: GameReady API not found")

func find_game_ready_api():
	if has_node("/root/GameReady"):
		var api = get_node("/root/GameReady")
		if api and api.has_method("is_initialized"):
			print("Found GameReadyAPI at /root/GameReady")
			return api
	
	if has_node("/root/GameReadyApI"):  # Опечатка в autoload?
		var api = get_node("/root/GameReadyApI")
		if api and api.has_method("is_initialized"):
			print("Found GameReadyAPI at /root/GameReadyApI")
			return api
	
	for child in get_tree().root.get_children():
		if child and child.has_method("is_initialized") and child.has_method("show_interstitial_ad"):
			print("Found GameReadyAPI in root children: ", child.name)
			return child
	
	print("GameReadyAPI not found immediately, waiting...")
	await get_tree().create_timer(0.5).timeout
	
	if has_node("/root/GameReady"):
		var api = get_node("/root/GameReady")
		if api and api.has_method("is_initialized"):
			print("Found GameReadyAPI on second attempt")
			return api
	
	if has_node("/root/GameReadyApI"):
		var api = get_node("/root/GameReadyApI")
		if api and api.has_method("is_initialized"):
			print("Found GameReadyAPI on second attempt")
			return api
	
	for child in get_tree().root.get_children():
		if child and child.has_method("is_initialized") and child.has_method("show_interstitial_ad"):
			print("Found GameReadyAPI on second attempt: ", child.name)
			return child
	
	return null

func initialize_leaderboard_manager():
	if has_node("/root/LeaderboardManager"):
		leaderboard_manager = get_node("/root/LeaderboardManager")
		
		if leaderboard_manager.has_method("is_initialized"):
			var timeout = 0.0
			while not leaderboard_manager.is_initialized() and timeout < 2.0:
				await get_tree().create_timer(0.1).timeout
				timeout += 0.1
		
		print("✓ LeaderboardManager initialized")
	else:
		print("✗ LeaderboardManager not found")

func check_initialization_complete():
	var critical_managers_ready = (
		localization_manager != null and
		asset_manager != null and 
		save_manager != null and
		sound_manager != null
	)
	
	if critical_managers_ready:
		_all_managers_ready = true
		_initialization_complete = true
		
		print("All managers initialized successfully")
		print("=== AppManager Initialization Complete ===")
		
		all_managers_initialized.emit()
		
		# Запускаем фоновую музыку
		call_deferred("start_background_music")
		
		# КРИТИЧЕСКИ ВАЖНО: Отправляем gameReady ПОСЛЕ загрузки музыки
		call_deferred("send_game_ready_signal")
	else:
		print("Some managers failed to initialize")
		_initialization_complete = true
		all_managers_initialized.emit()

func start_background_music():
	if sound_manager and sound_manager.has_method("play_music"):
		await get_tree().create_timer(0.5).timeout
		
		if asset_manager and asset_manager.has_method("get_current_music"):
			var music_stream = asset_manager.get_current_music()
			if music_stream:
				sound_manager.play_music(music_stream)
				print("Background music started")
			else:
				print("No music stream available from AssetManager")
		else:
			print("AssetManager not available for music")
	else:
		print("SoundManager or play_music method not available")

# НОВЫЙ МЕТОД: Отправка gameReady когда ВСЁ загружено
func send_game_ready_signal():
	if _game_ready_sent:
		print("GameReady already sent, skipping")
		return
	
	# Дополнительная задержка для уверенности что всё загружено
	await get_tree().create_timer(0.5).timeout
	
	if game_ready_api and game_ready_api.has_method("send_game_ready"):
		print("=== Sending gameReady to Yandex ===")
		game_ready_api.send_game_ready()
		_game_ready_sent = true
		game_fully_ready.emit()
		print("=== Game is fully ready for player ===")
	else:
		print("GameReady API not available for sending gameReady")
		_game_ready_sent = true
		game_fully_ready.emit()

# Геттеры
func get_localization_manager() -> LocalizationManager:
	return localization_manager

func get_asset_manager() -> AssetManager:
	return asset_manager

func get_save_manager() -> SaveManager:
	return save_manager

func get_sound_manager() -> SoundManager:
	return sound_manager

func get_game_mode_manager():
	return game_mode_manager

func get_viewport_handler() -> ViewportHandler:
	return viewport_handler

func get_game_ready_api():
	return game_ready_api

func get_leaderboard_manager() -> LeaderboardManager:
	return leaderboard_manager

func are_all_managers_ready() -> bool:
	return _all_managers_ready

func is_initialization_complete() -> bool:
	return _initialization_complete

func is_game_ready_sent() -> bool:
	return _game_ready_sent

func get_initialization_status() -> Dictionary:
	return {
		"localization_manager": localization_manager != null,
		"asset_manager": asset_manager != null,
		"save_manager": save_manager != null,
		"sound_manager": sound_manager != null,
		"game_mode_manager": game_mode_manager != null,
		"viewport_handler": viewport_handler != null,
		"game_ready_api": game_ready_api != null,
		"leaderboard_manager": leaderboard_manager != null,
		"all_managers_ready": _all_managers_ready,
		"initialization_complete": _initialization_complete,
		"game_ready_sent": _game_ready_sent
	}
