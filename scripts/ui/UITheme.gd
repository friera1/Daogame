extends Node

const COLOR_BG = Color("0B120F")
const COLOR_PANEL = Color("122019")
const COLOR_CARD = Color("173026")
const COLOR_JADE = Color("2FAF7F")
const COLOR_JADE_LIGHT = Color("4FBF9F")
const COLOR_JADE_DARK = Color("1E7D63")
const COLOR_GOLD = Color("D8B66A")
const COLOR_GOLD_DARK = Color("9E7B37")
const COLOR_TEXT = Color("F2E9D8")
const COLOR_TEXT_SECONDARY = Color("CDBF9F")
const COLOR_MUTED = Color("7D7A6E")
const COLOR_SUCCESS = Color("56C778")
const COLOR_DANGER = Color("C24C3A")

static func apply_lobby_style(root: Control) -> void:
	_apply_recursive(root)

static func _apply_recursive(node: Node) -> void:
	if node is Button:
		_style_button(node)
	elif node is PanelContainer:
		_style_panel(node)
	elif node is Label:
		_style_label(node)
	elif node is RichTextLabel:
		_style_rich_label(node)

	for child in node.get_children():
		_apply_recursive(child)

static func _style_button(button: Button) -> void:
	button.modulate = COLOR_TEXT
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_font_size_override("font_size", 20)

static func _style_panel(panel: PanelContainer) -> void:
	panel.modulate = Color(1, 1, 1, 0.96)

static func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 20)

static func _style_rich_label(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", COLOR_TEXT)
	label.add_theme_font_size_override("normal_font_size", 20)
