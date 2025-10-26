extends Node

# Звуковой менеджер для управления музыкой и звуковыми эффектами

# Громкости
var master_volume: float = 0.8
var music_volume: float = 0.4
var sfx_volume: float = 0.8

# Аудиоплееры
var music_player: AudioStreamPlayer
var sfx_players: Array = []

# Флаги
var _is_initialized: bool = false
var _current_music: AudioStream

# Сигналы
signal music_started()
signal music_stopped()
signal music_paused()
signal music_resumed()

func _ready():
	initialize()

func initialize():
	if _is_initialized:
		return
	
	print("SoundManager initializing...")
	
	# Создаем аудиоплеер для музыки
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = linear_to_db(master_volume * music_volume)
	music_player.finished.connect(_on_music_finished)
	
	# Создаем несколько аудиоплееров для звуковых эффектов (пул из 5)
	for i in range(5):
		var sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)
		sfx_players.append(sfx_player)
		sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
	
	_is_initialized = true
	print("SoundManager initialized")

func is_initialized() -> bool:
	return _is_initialized

# Управление громкостью
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	print("Master volume set to: ", master_volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	print("Music volume set to: ", music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	print("SFX volume set to: ", sfx_volume)

func update_volumes():
	if music_player:
		music_player.volume_db = linear_to_db(master_volume * music_volume)
	
	for sfx_player in sfx_players:
		sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)

# Управление музыкой
func play_music(music_stream: AudioStream):
	if not music_player:
		return
	
	# Если уже играет эта музыка, не перезапускаем
	if music_player.stream == music_stream and music_player.playing:
		return
	
	_current_music = music_stream
	music_player.stream = music_stream
	music_player.volume_db = linear_to_db(master_volume * music_volume)
	music_player.play()
	music_started.emit()
	print("Playing music: ", music_stream.resource_path if music_stream else "None")

func stop_music():
	if music_player:
		music_player.stop()
		music_stopped.emit()
		print("Music stopped")

func pause_music():
	if music_player and music_player.playing:
		music_player.stream_paused = true
		music_paused.emit()
		print("Music paused")

func resume_music():
	if music_player:
		music_player.stream_paused = false
		music_resumed.emit()
		print("Music resumed")

func force_pause_music():
	"""Принудительная пауза (например, при показе рекламы)"""
	if music_player and music_player.playing:
		music_player.stream_paused = true
		print("Music force paused")

func force_resume_music():
	"""Принудительное возобновление музыки (например, после скрытия рекламы)"""
	if music_player:
		music_player.stream_paused = false
		music_resumed.emit()
		print("Music force resumed")

func stop_music_immediate():
	"""Немедленная остановка музыки (при выходе из игры)"""
	if music_player:
		music_player.stop()
		music_player.stream = null
		print("Music stopped immediately")

# Звуковые эффекты
func play_sfx(sfx_stream: AudioStream):
	for sfx_player in sfx_players:
		if not sfx_player.playing:
			sfx_player.stream = sfx_stream
			sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
			sfx_player.play()
			return
	
	# Если все плееры заняты, создаем новый
	var new_sfx_player = AudioStreamPlayer.new()
	add_child(new_sfx_player)
	new_sfx_player.stream = sfx_stream
	new_sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
	new_sfx_player.play()
	sfx_players.append(new_sfx_player)

func stop_all_sfx():
	for sfx_player in sfx_players:
		sfx_player.stop()

# Обработчики событий
func _on_music_finished():
	# Если музыка закончилась, можно повторить или перейти к следующему треку
	print("Music finished playing")
	# Автоповтор музыки
	if music_player and _current_music:
		music_player.play()

# Управление фокусом окна - ИСПРАВЛЕНО ДЛЯ МОБИЛЬНЫХ УСТРОЙСТВ
func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# Когда окно теряет фокус, приостанавливаем музыку
			if music_player and music_player.playing:
				music_player.stream_paused = true
				print("Window focus lost - music paused")
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			# Когда окно получает фокус, возобновляем музыку
			if music_player and music_player.stream_paused:
				music_player.stream_paused = false
				print("Window focus gained - music resumed")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Для мобильных устройств - при сворачивании приложения
			if music_player and music_player.playing:
				music_player.stream_paused = true
				print("App focus lost - music paused")
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Для мобильных устройств - при разворачивании приложения
			if music_player and music_player.stream_paused:
				music_player.stream_paused = false
				print("App focus gained - music resumed")
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Для Android - при нажатии кнопки назад
			if music_player and music_player.playing:
				music_player.stream_paused = true
				print("Back button pressed - music paused")

# Получение текущих настроек громкости
func get_audio_settings() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}

# Загрузка настроек звука
func load_audio_settings(settings: Dictionary):
	if settings.has("master_volume"):
		set_master_volume(settings["master_volume"])
	if settings.has("music_volume"):
		set_music_volume(settings["music_volume"])
	if settings.has("sfx_volume"):
		set_sfx_volume(settings["sfx_volume"])

# Статус звуковой системы
func get_status() -> Dictionary:
	return {
		"initialized": _is_initialized,
		"music_playing": music_player.playing if music_player else false,
		"music_paused": music_player.stream_paused if music_player else false,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"active_sfx_players": get_active_sfx_count()
	}

func get_active_sfx_count() -> int:
	var count = 0
	for sfx_player in sfx_players:
		if sfx_player.playing:
			count += 1
	return count

# Очистка ресурсов
func _exit_tree():
	print("SoundManager: Cleaning up resources")
	stop_music_immediate()
	stop_all_sfx()
	
	for sfx_player in sfx_players:
		if is_instance_valid(sfx_player):
			sfx_player.queue_free()
	sfx_players.clear()
