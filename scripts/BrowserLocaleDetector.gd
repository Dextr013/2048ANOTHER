extends Node
class_name BrowserLocaleDetector

# JavaScript integration for WebGL builds
const JAVASCRIPT_CODE = """
function getBrowserLanguage() {
	const lang = navigator.language || navigator.userLanguage;
	return lang;
}

function getBrowserLanguages() {
	return navigator.languages || [navigator.language || navigator.userLanguage];
}

// Export functions for Godot
window.getBrowserLanguage = getBrowserLanguage;
window.getBrowserLanguages = getBrowserLanguages;
"""

# Detected locale information
var detected_language: LocalizationManager.Language = LocalizationManager.Language.ENGLISH
var browser_locale: String = ""
var is_web_build: bool = false

func _ready():
	# Check if we're running in a web environment
	is_web_build = OS.get_name() == "Web"
	
	if is_web_build:
		setup_web_locale_detection()
	else:
		# Fallback to OS locale detection
		detect_system_locale()

func setup_web_locale_detection():
	# Inject JavaScript code for locale detection
	if is_web_build:
		var js_interface = JavaScriptBridge
		if js_interface:
			# Execute the JavaScript code
			js_interface.eval(JAVASCRIPT_CODE)
			
			# Get the browser language
			var browser_lang = js_interface.eval("getBrowserLanguage()", true)
			if browser_lang is String:
				browser_locale = browser_lang
			else:
				browser_locale = "en"
			
			print("Detected browser locale: ", browser_locale)
			
			# Determine the game language based on browser locale
			determine_language_from_locale(browser_locale)
		else:
			print("JavaScript interface not available, using default locale")
			detect_system_locale()
	else:
		detect_system_locale()

func detect_system_locale():
	# Fallback for non-web builds
	var system_locale = OS.get_locale()
	browser_locale = system_locale
	determine_language_from_locale(system_locale)
	print("Detected system locale: ", system_locale)

func determine_language_from_locale(locale: String):
	# Convert locale to our supported languages
	locale = locale.to_lower()
	
	# Check for Russian variants
	if locale.begins_with("ru") or locale.begins_with("be") or locale.begins_with("uk"):
		detected_language = LocalizationManager.Language.RUSSIAN
		print("Selected Russian language based on locale: ", locale)
	else:
		# Default to English for all other locales
		detected_language = LocalizationManager.Language.ENGLISH  
		print("Selected English language based on locale: ", locale)

func get_detected_language() -> LocalizationManager.Language:
	return detected_language

func get_browser_locale() -> String:
	return browser_locale

func is_russian_locale() -> bool:
	return detected_language == LocalizationManager.Language.RUSSIAN

func is_web_environment() -> bool:
	return is_web_build

# Additional utility functions for splash screen selection
func get_splash_screen_suffix() -> String:
	if is_russian_locale():
		return "_ru"
	else:
		return "_en"

func get_localized_splash_path(base_path: String) -> String:
	# Remove file extension and add locale suffix
	var path_without_ext = base_path.get_basename()
	var extension = base_path.get_extension()
	
	return path_without_ext + get_splash_screen_suffix() + "." + extension

# Apply detected locale to LocalizationManager
func apply_detected_locale():
	if LocalizationManager:
		LocalizationManager.set_language(detected_language)
		print("Applied detected language: ", detected_language)
	else:
		print("LocalizationManager not available, cannot apply locale")

# Debug function to get all browser language info
func get_debug_info() -> Dictionary:
	var debug_info = {
		"detected_language": detected_language,
		"browser_locale": browser_locale,
		"is_web_build": is_web_build,
		"splash_suffix": get_splash_screen_suffix()
	}
	
	if is_web_build and JavaScriptBridge:
		var js_interface = JavaScriptBridge
		var all_languages = js_interface.eval("getBrowserLanguages()", true)
		if all_languages:
			debug_info["all_browser_languages"] = all_languages
	
	return debug_info
