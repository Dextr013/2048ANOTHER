class_name Startup
extends Control

func _ready():
	# Show splash screen first if needed
	if SplashScreen.should_show_splash():
		show_splash_screen()
	else:
		go_to_main_menu()

func show_splash_screen():
	var splash = SplashScreen.new()
	add_child(splash)
	splash.splash_finished.connect(_on_splash_finished)

func _on_splash_finished():
	# Use call_deferred to avoid issues with child removal during signal processing
	call_deferred("go_to_main_menu")

func go_to_main_menu():
	# Clean up any existing children safely
	for child in get_children():
		if child is SplashScreen:
			child.call_deferred("queue_free")
	
	# Change scene with call_deferred to ensure safe cleanup
	call_deferred("_change_to_main_menu")

func _change_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
