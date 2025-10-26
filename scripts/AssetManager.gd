extends Node

const BACKGROUNDS = [
	"res://assets/background/Mainmenu.webp",
	"res://assets/background/bg1.webp",
	"res://assets/background/bg2.webp",
	"res://assets/background/bg3.webp",
	"res://assets/background/bg4.webp",
	"res://assets/background/bg5.webp",
	"res://assets/background/bg6.webp",
	"res://assets/background/bg7.webp"
]

const MUSIC_TRACKS = [
	"res://assets/audio/music/track_1.ogg",
	"res://assets/audio/music/track_2.ogg",
	"res://assets/audio/music/track_3.ogg"
]

const SPLASH_SCREENS = {
	"en": "res://assets/splash/splash_en.png",
	"ru": "res://assets/splash/splash_ru.png"
}

const TILE_TEXTURES = {
	2: "res://assets/graphics/tiles/tile_2.png",
	4: "res://assets/graphics/tiles/tile_4.png",
	8: "res://assets/graphics/tiles/tile_8.png",
	16: "res://assets/graphics/tiles/tile_16.png",
	32: "res://assets/graphics/tiles/tile_32.png",
	64: "res://assets/graphics/tiles/tile_64.png",
	128: "res://assets/graphics/tiles/tile_128.png",
	256: "res://assets/graphics/tiles/tile_256.png",
	512: "res://assets/graphics/tiles/tile_512.png",
	1024: "res://assets/graphics/tiles/tile_1024.png",
	2048: "res://assets/graphics/tiles/tile_2048.png",
	-1: "res://assets/graphics/tiles/Block.png"
}

# Кэшированные ресурсы
var background_textures: Array = []  # Убрана типизация для совместимости
var music_streams: Array = []        # Убрана типизация для совместимости
var splash_textures: Dictionary = {}
var tile_textures: Dictionary = {}

var current_background_index: int = 0
var current_music_index: int = 0
var is_loading: bool = false

# Флаг для критических ресурсов
var _critical_assets_loaded: bool = false

func _ready():
	print("AssetManager initializing...")
	
	# Синхронная загрузка критичных ресурсов
	load_critical_assets()
	
	# Асинхронная загрузка остального
	call_deferred("load_remaining_assets_async")

func load_critical_assets():
	# Главный фон меню
	var main_menu_bg = load("res://assets/background/Mainmenu.webp")
	if main_menu_bg:
		background_textures.append(main_menu_bg)
	else:
		background_textures.append(create_fallback_texture())
		print("Failed to load main menu background")
	
	# Первый музыкальный трек
	var first_music = load("res://assets/audio/music/track_1.ogg")
	if first_music:
		music_streams.append(first_music)
	else:
		music_streams.append(create_fallback_audio())
		print("Failed to load first music track")
	
	# Сплэш-экраны
	load_splash_screens()
	
	# Критичные плитки (2, 4, 8, препятствие)
	load_essential_tile_textures()
	
	_critical_assets_loaded = true
	print("Critical assets loaded")

func load_splash_screens():
	for locale in SPLASH_SCREENS:
		var path = SPLASH_SCREENS[locale]
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				splash_textures[locale] = texture

func load_essential_tile_textures():
	var essential_tiles = [2, 4, 8, -1]
	for tile_value in essential_tiles:
		if TILE_TEXTURES.has(tile_value):
			var path = TILE_TEXTURES[tile_value]
			if ResourceLoader.exists(path):
				var texture = load(path)
				if texture:
					tile_textures[tile_value] = texture

func load_remaining_assets_async():
	if is_loading:
		return
	
	is_loading = true
	print("Loading remaining assets asynchronously...")
	
	# Фоны
	for i in range(1, BACKGROUNDS.size()):
		var path = BACKGROUNDS[i]
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				background_textures.append(texture)
			else:
				background_textures.append(create_fallback_texture())
		else:
			background_textures.append(create_fallback_texture())
		
		await get_tree().process_frame
	
	# Музыка
	for i in range(1, MUSIC_TRACKS.size()):
		var path = MUSIC_TRACKS[i]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				music_streams.append(stream)
			else:
				music_streams.append(create_fallback_audio())
		else:
			music_streams.append(create_fallback_audio())
		
		await get_tree().process_frame
	
	# Остальные плитки
	await load_remaining_tile_textures_async()
	
	is_loading = false
	print("All assets loaded: ", background_textures.size(), " backgrounds, ", music_streams.size(), " tracks")

func load_remaining_tile_textures_async():
	for tile_value in TILE_TEXTURES:
		if not tile_textures.has(tile_value):
			var path = TILE_TEXTURES[tile_value]
			if ResourceLoader.exists(path):
				var texture = load(path)
				if texture:
					tile_textures[tile_value] = texture
			
			await get_tree().process_frame

# Геттеры
func get_current_background():
	if background_textures.size() > 0:
		var index = current_background_index % background_textures.size()
		return background_textures[index]
	return create_fallback_texture()

func get_current_music():
	if music_streams.size() > 0:
		var index = current_music_index % music_streams.size()
		return music_streams[index]
	return create_fallback_audio()

func get_tile_texture(value: int):
	if tile_textures.has(value):
		return tile_textures[value]
	
	# Ленивая загрузка
	if TILE_TEXTURES.has(value):
		var path = TILE_TEXTURES[value]
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				tile_textures[value] = texture
				return texture
	
	# Фолбэк для отсутствующей текстуры
	return create_fallback_tile_texture(value)

func get_splash_texture(locale: String):
	return splash_textures.get(locale, null)

# Управление фонами
func get_background_count() -> int:
	return max(1, background_textures.size())

func set_background_index(index: int):
	if background_textures.size() > 0:
		current_background_index = clamp(index, 0, background_textures.size() - 1)
	else:
		current_background_index = 0

func next_background():
	current_background_index = (current_background_index + 1) % get_background_count()

func previous_background():
	current_background_index = (current_background_index - 1 + get_background_count()) % get_background_count()

# Управление музыкой
func get_music_count() -> int:
	return max(1, music_streams.size())

func set_music_index(index: int):
	if music_streams.size() > 0:
		current_music_index = clamp(index, 0, music_streams.size() - 1)
	else:
		current_music_index = 0

func next_music():
	current_music_index = (current_music_index + 1) % get_music_count()

func previous_music():
	current_music_index = (current_music_index - 1 + get_music_count()) % get_music_count()

# Сохранение настроек
func save_asset_settings():
	var config = ConfigFile.new()
	config.set_value("assets", "background_index", current_background_index)
	config.set_value("assets", "music_index", current_music_index)
	var err = config.save("user://asset_settings.cfg")
	if err != OK:
		print("Error saving asset settings: ", err)

func load_asset_settings():
	var config = ConfigFile.new()
	var err = config.load("user://asset_settings.cfg")
	
	if err == OK:
		current_background_index = config.get_value("assets", "background_index", 0)
		current_music_index = config.get_value("assets", "music_index", 0)
		
		# Валидация индексов
		if background_textures.size() > 0:
			current_background_index = clamp(current_background_index, 0, background_textures.size() - 1)
		if music_streams.size() > 0:
			current_music_index = clamp(current_music_index, 0, music_streams.size() - 1)

# Фолбэки
func create_fallback_texture():
	var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 0.2, 0.3, 1.0))
	var texture = ImageTexture.create_from_image(image)
	return texture

func create_fallback_audio():
	# Создаем простой AudioStream с тишиной вместо генератора
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	return stream

func create_fallback_tile_texture(value: int):
	# Создаем простую текстуру для плитки с номером
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	# Разные цвета для разных значений
	var color = Color(0.8, 0.8, 0.8, 1.0)
	if value == -1:
		color = Color(0.3, 0.3, 0.3, 1.0)  # Темный для препятствий
	elif value <= 8:
		color = Color(0.9, 0.9, 0.8, 1.0)
	elif value <= 64:
		color = Color(0.9, 0.8, 0.6, 1.0)
	else:
		color = Color(0.9, 0.6, 0.4, 1.0)
	
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	return texture

# Статус загрузки
func are_critical_assets_loaded() -> bool:
	return _critical_assets_loaded

func get_loading_status() -> Dictionary:
	return {
		"critical_loaded": _critical_assets_loaded,
		"backgrounds_loaded": background_textures.size(),
		"music_tracks_loaded": music_streams.size(),
		"tile_textures_loaded": tile_textures.size(),
		"is_loading": is_loading
	}

# Проверка существования ресурсов
func has_backgrounds() -> bool:
	return background_textures.size() > 0

func has_music() -> bool:
	return music_streams.size() > 0

func has_tile_texture(value: int) -> bool:
	return tile_textures.has(value)
