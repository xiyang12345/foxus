#
# Language Selector - Foxus
# Provides UI for switching between languages
#

extends VBoxContainer

onready var language_manager = get_node("/root/LanguageManager")

func _ready():
    # Create language buttons
    var locales = language_manager.get_supported_locales()
    var current_locale = language_manager.get_current_locale()

    for locale_info in locales:
        var button = Button.new()
        button.text = locale_info.name + " (" + locale_info.code + ")"
        button.name = "btn_" + locale_info.code

        # Highlight current language
        if locale_info.code == current_locale:
            button.modulate = Color(0, 1, 0)  # Green for selected

        button.connect("pressed", self, "on_language_selected", [locale_info.code])
        add_child(button)

    # Add a back button
    var back_button = Button.new()
    back_button.text = language_manager.tr("ui.buttons.cancel")
    back_button.connect("pressed", self, "on_back_pressed")
    add_child(back_button)

func on_language_selected(locale_code):
    language_manager.set_locale(locale_code)
    # Update button colors
    for child in get_children():
        if child is Button:
            if child.name == "btn_" + locale_code:
                child.modulate = Color(0, 1, 0)  # Green for selected
            else:
                child.modulate = Color(1, 1, 1)  # White for others

func on_back_pressed():
    hide()