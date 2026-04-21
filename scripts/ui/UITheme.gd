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
	button.add_theme_constant_override("h_separation", 8)

static func _style_panel(panel: PanelContainer) -> void:
	panel.modulate = Color(1, 1, 1, 0.96)

static func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 20)

static func _style_rich_label(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", COLOR_TEXT)
	label.add_theme_font_size_override("normal_font_size", 20)

static func make_card_style(border_color: Color = COLOR_JADE_DARK, bg_alpha: float = 0.92) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_CARD, bg_alpha)
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

static func make_button_style(fill_color: Color, border_color: Color, font_color: Color = COLOR_TEXT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style

static func apply_card(panel: PanelContainer, border_color: Color = COLOR_JADE_DARK) -> void:
	panel.add_theme_stylebox_override("panel", make_card_style(border_color))

static func apply_accent_button(button: Button, is_gold: bool = false) -> void:
	var fill := COLOR_GOLD if is_gold else COLOR_JADE_DARK
	var border := COLOR_GOLD_DARK if is_gold else COLOR_JADE_LIGHT
	var font := COLOR_BG if is_gold else COLOR_TEXT
	button.add_theme_stylebox_override("normal", make_button_style(fill, border, font))
	button.add_theme_stylebox_override("hover", make_button_style(fill.lightened(0.08), border, font))
	button.add_theme_stylebox_override("pressed", make_button_style(fill.darkened(0.08), border, font))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
