extends Control

const SHOP_BG_PATH := "res://assets/art/generated/lobby_background_primary.png"
const SHOP_BANNER_PATH := "res://assets/art/generated/shop_banner_primary.png"

@onready var offer_list: VBoxContainer = %OfferList
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var shop_background_art: TextureRect = %ShopBackgroundArt
@onready var banner_art: TextureRect = %BannerArt
@onready var header_title: Label = %HeaderTitle

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_apply_visual_polish()
	_apply_art()
	_refresh()

func _apply_visual_polish() -> void:
	header_title.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	header_title.add_theme_font_size_override("font_size", 28)
	detail_label.add_theme_color_override("default_color", UITheme.COLOR_TEXT)

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(SHOP_BG_PATH)
	if bg != null:
		shop_background_art.texture = bg
	var banner := ArtLoader.load_texture_safe(SHOP_BANNER_PATH)
	if banner != null:
		banner_art.texture = banner

func _refresh() -> void:
	for child in offer_list.get_children():
		child.queue_free()
	for offer in ConfigRepository.shop_offers.get("offers", []):
		var offer_id := str(offer.get("id", ""))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s · %s нефрита" % [str(offer.get("title", offer_id)), str(offer.get("price_jade", 0))]
		label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
		var open_button := Button.new()
		open_button.text = "Детали"
		open_button.pressed.connect(_show_offer.bind(offer_id))
		var buy_button := Button.new()
		buy_button.text = "Купить"
		buy_button.modulate = UITheme.COLOR_GOLD
		buy_button.add_theme_color_override("font_color", UITheme.COLOR_BG)
		buy_button.pressed.connect(_buy_offer.bind(offer))
		row.add_child(label)
		row.add_child(open_button)
		row.add_child(buy_button)
		offer_list.add_child(row)
	if ConfigRepository.shop_offers.get("offers", []).size() > 0:
		_show_offer(str(ConfigRepository.shop_offers.get("offers", [])[0].get("id", "")))

func _show_offer(offer_id: String) -> void:
	for offer in ConfigRepository.shop_offers.get("offers", []):
		if str(offer.get("id", "")) != offer_id:
			continue
		detail_label.text = "[b]%s[/b]\n\nТег: %s\nЦена: %s нефрита\nКоличество: %s %s" % [
			str(offer.get("title", offer_id)),
			str(offer.get("tag", "daily")),
			str(offer.get("price_jade", 0)),
			str(offer.get("amount", 0)),
			str(offer.get("currency", "item"))
		]
		return
	detail_label.text = "Предложение не найдено"

func _buy_offer(offer: Dictionary) -> void:
	var price := int(offer.get("price_jade", 0))
	if not PlayerState.spend_currency("jade", price):
		detail_label.text = "[b]Недостаточно нефрита[/b]"
		return
	var currency_id := str(offer.get("currency", "gold"))
	var amount := int(offer.get("amount", 0))
	if currency_id == "breakthrough_stone":
		detail_label.text = "[b]Покупка совершена[/b]\n\nНабор прорыва отмечен как купленный. Интеграция в инвентарь будет следующим шагом."
		return
	PlayerState.add_currency(currency_id, amount)
	detail_label.text = "[b]Покупка совершена[/b]\n\nПолучено: %s %s" % [str(amount), currency_id]

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
