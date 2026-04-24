extends Node

const COLOR_BG = Color("071012")
const COLOR_BG_SOFT = Color("0D171A")
const COLOR_PANEL = Color("111D22")
const COLOR_PANEL_ALT = Color("17262C")
const COLOR_CARD = Color("182930")
const COLOR_CARD_SOFT = Color("20353D")
const COLOR_OVERLAY = Color("0B1518")
const COLOR_JADE = Color("31D6A2")
const COLOR_JADE_LIGHT = Color("73F0C7")
const COLOR_JADE_DARK = Color("139B78")
const COLOR_CYAN = Color("69D8FF")
const COLOR_GOLD = Color("F4C96A")
const COLOR_GOLD_DARK = Color("B88935")
const COLOR_ORANGE = Color("F59E5B")
const COLOR_TEXT = Color("F7EFE0")
const COLOR_TEXT_SECONDARY = Color("B8C4C2")
const COLOR_TEXT_SOFT = Color("E5D7BE")
const COLOR_MUTED = Color("6E7B7B")
const COLOR_SUCCESS = Color("55D98A")
const COLOR_DANGER = Color("FF5D5D")
const COLOR_WARNING = Color("F2B84B")
const COLOR_PURPLE = Color("B688FF")

const FONT_SIZE_BODY := 18
const FONT_SIZE_BUTTON := 18
const FONT_SIZE_TITLE := 26
const FONT_SIZE_SMALL := 14

static func apply_lobby_style(root: Control) -> void:
	root.modulate = Color(1, 1, 1, 1)
	root.add_theme_constant_override("margin_left", 0)
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
	elif node is LineEdit:
		_style_line_edit(node)
	elif node is ScrollContainer:
		_style_scroll(node)
	elif node is VBoxContainer or node is HBoxContainer:
		node.add_theme_constant_override("separation", 10)
	elif node is GridContainer:
		node.add_theme_constant_override("h_separation", 10)
		node.add_theme_constant_override("v_separation", 10)
	for child in node.get_children():
		_apply_recursive(child)

static func _style_button(button: Button) -> void:
	button.custom_minimum_size.y = max(button.custom_minimum_size.y, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_stylebox_override("normal", make_button_style(Color(COLOR_PANEL_ALT, 0.94), Color(COLOR_JADE_DARK, 0.45), COLOR_TEXT))
	button.add_theme_stylebox_override("hover", make_button_style(Color(COLOR_CARD_SOFT, 1.0), Color(COLOR_JADE_LIGHT, 0.85), COLOR_TEXT))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(COLOR_JADE_DARK, 0.96), COLOR_JADE_LIGHT, COLOR_BG))
	button.add_theme_stylebox_override("disabled", make_button_style(Color(COLOR_PANEL, 0.55), Color(COLOR_MUTED, 0.35), COLOR_MUTED))

static func _style_panel(panel: PanelContainer) -> void:
	panel.modulate = Color(1, 1, 1, 1)
	if not panel.has_theme_stylebox_override("panel"):
		panel.add_theme_stylebox_override("panel", make_panel_style())

static func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

static func _style_rich_label(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", COLOR_TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.22))
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE_BODY)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE_BODY)
	label.scroll_active = false
	label.fit_content = true

static func _style_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_color_override("font_color", COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	line_edit.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	line_edit.add_theme_stylebox_override("normal", make_card_style(COLOR_JADE_DARK, 0.72, 18))
	line_edit.add_theme_stylebox_override("focus", make_card_style(COLOR_JADE_LIGHT, 0.78, 18))

static func _style_scroll(scroll: ScrollContainer) -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

static func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_PANEL, 0.92)
	style.border_color = Color(COLOR_JADE_DARK, 0.22)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	return style

static func make_card_style(border_color: Color = COLOR_JADE_DARK, bg_alpha: float = 0.88, radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(COLOR_CARD, bg_alpha)
	style.border_color = Color(border_color, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 10
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	return style

static func make_button_style(fill_color: Color, border_color: Color, font_color: Color = COLOR_TEXT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color(border_color, 0.85)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 6
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	return style

static func make_pill_style(fill_color: Color = COLOR_PANEL_ALT, border_color: Color = COLOR_JADE_DARK) -> StyleBoxFlat:
	var style := make_button_style(Color(fill_color, 0.76), Color(border_color, 0.55))
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	return style

static func apply_card(panel: PanelContainer, border_color: Color = COLOR_JADE_DARK) -> void:
	panel.add_theme_stylebox_override("panel", make_card_style(border_color))

static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_panel_style())

static func apply_accent_button(button: Button, is_gold: bool = false) -> void:
	var fill := Color(COLOR_GOLD, 0.96) if is_gold else Color(COLOR_JADE_DARK, 0.96)
	var border := COLOR_GOLD if is_gold else COLOR_JADE_LIGHT
	var font := COLOR_BG if is_gold else COLOR_TEXT
	button.add_theme_stylebox_override("normal", make_button_style(fill, border, font))
	button.add_theme_stylebox_override("hover", make_button_style(fill.lightened(0.08), border.lightened(0.12), font))
	button.add_theme_stylebox_override("pressed", make_button_style(fill.darkened(0.12), border, font))
	button.add_theme_stylebox_override("disabled", make_button_style(Color(COLOR_PANEL, 0.55), Color(COLOR_MUTED, 0.35), COLOR_MUTED))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)

static func style_title(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)

static func style_caption(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)

static func rarity_color(rarity: String) -> Color:
	match rarity:
		"mythic":
			return COLOR_ORANGE
		"legendary":
			return COLOR_GOLD
		"epic":
			return COLOR_PURPLE
		"rare":
			return COLOR_CYAN
		"uncommon":
			return COLOR_SUCCESS
		_:
			return COLOR_TEXT_SECONDARY
