#
# Language Manager - Foxus
# Manages internationalization (i18n) and language switching
#

extends Node

signal language_changed(locale_code)

var current_locale = "en"
var translations = {}

const LOCALES_DIR = "res://locales/"
const SUPPORTED_LOCALES = ["en", "zh_CN"]

func _ready():
    load_all_translations()
    # Try to load saved language preference
    load_language_preference()

func load_all_translations():
    for locale in SUPPORTED_LOCALES:
        var file_path = LOCALES_DIR + locale + ".json"
        var file = File.new()
        if file.file_exists(file_path):
            file.open(file_path, File.READ)
            var content = file.get_as_text()
            file.close()
            translations[locale] = parse_json(content)
            print("Loaded translations for: ", locale)
        else:
            print("Warning: Translation file not found: ", file_path)

func set_locale(locale_code):
    if translations.has(locale_code):
        current_locale = locale_code
        save_language_preference()
        emit_signal("language_changed", locale_code)
        print("Language changed to: ", locale_code)
    else:
        print("Warning: Locale not supported: ", locale_code)

func get_current_locale():
    return current_locale

func tr(key_path):
    """Translate a key path like 'ui.status.not_connected'"""
    var keys = key_path.split(".")
    var current = translations.get(current_locale, {})

    for key in keys:
        if current.has(key):
            current = current[key]
        else:
            print("Warning: Translation key not found: ", key_path)
            return key_path

    return current

func get_locale_name(locale_code):
    if translations.has(locale_code) and translations[locale_code].has("locale_name"):
        return translations[locale_code]["locale_name"]
    return locale_code

func get_supported_locales():
    var result = []
    for locale in SUPPORTED_LOCALES:
        result.append({
            "code": locale,
            "name": get_locale_name(locale)
        })
    return result

func save_language_preference():
    var file = File.new()
    file.open("user://language.cfg", File.WRITE)
    file.store_string(current_locale)
    file.close()

func load_language_preference():
    var file = File.new()
    if file.file_exists("user://language.cfg"):
        file.open("user://language.cfg", File.READ)
        var saved_locale = file.get_as_text().strip_edges()
        file.close()
        if translations.has(saved_locale):
            current_locale = saved_locale
            print("Loaded language preference: ", current_locale)