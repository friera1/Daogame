extends Control

const SHOP_BG_PATH := "res://assets/art/generated/lobby_background_primary.png"
const SHOP_BANNER_PATH := "res://assets/art/generated/shop_banner_primary.png"
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

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
	GameSession.refresh_live_ops_state()
	for child in offer_list.get_children():
		child.queue_free()
	var jade_balance := int(PlayerState.get_currencies().get("jade", 0))
	for offer in ConfigRepository.shop_offers.get("offers", []):
		var offer_id := str(offer.get("id", ""))
		var price := int(offer.get("price_jade", 0))
		var live_state := GameSession.get_shop_offer_state(offer_id)
		var enabled := bool(live_state.get("enabled", true))
		var affordable := jade_balance >= price and enabled
		var badge := "[ROTATION]" if not enabled else "[ГОТОВО]" if affordable else "[НЕТ НЕФРИТА]"
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if affordable else UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_item_icon(str(offer.get("currency", "")))
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s %s · %s нефрита" % [badge, str(offer.get("title", offer_id)), str(price)]
		label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
		var open_button := Button.new()
		open_button.text = "Детали"
		open_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(open_button, false)
		open_button.pressed.connect(_show_offer.bind(offer_id))
		var buy_button := Button.new()
		buy_button.text = "Купить"
		buy_button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(buy_button, true)
		buy_button.disabled = not affordable
		buy_button.pressed.connect(_buy_offer.bind(offer))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(open_button)
		row.add_child(buy_button)
		offer_list.add_child(card)
	if ConfigRepository.shop_offers.get("offers", []).size() > 0:
		_show_offer(str(ConfigRepository.shop_offers.get("offers", [])[0].get("id", "")))

func _show_offer(offer_id: String) -> void:
	for offer in ConfigRepository.shop_offers.get("offers", []):
		if str(offer.get("id", "")) != offer_id:
			continue
		var price := int(offer.get("price_jade", 0))
		var jade_balance := int(PlayerState.get_currencies().get("jade", 0))
		var live_state := GameSession.get_shop_offer_state(offer_id)
		var enabled := bool(live_state.get("enabled", true))
		var state := "ротация закрыта" if not enabled else "доступно" if jade_balance >= price else "не хватает нефрита"
		detail_label.text = "[b]%s[/b]\n\nТег: %s\nЦена: %s нефрита\nКоличество: %s %s\nLive-cycle: %s\nСтатус: %s" % [
			str(offer.get("title", offer_id)),
			str(offer.get("tag", "daily")),
			str(price),
			str(offer.get("amount", 0)),
			str(offer.get("currency", "item")),
			str(live_state.get("cycle", 0)),
			state
		]
		return
	detail_label.text = "Предложение не найдено"

func _buy_offer(offer: Dictionary) -> void:
	var offer_id := str(offer.get("id", ""))
	var live_state := GameSession.get_shop_offer_state(offer_id)
	if not bool(live_state.get("enabled", true)):
		detail_label.text = "[b]Предложение временно недоступно[/b]"
		_refresh()
		return
	var price := int(offer.get("price_jade", 0))
	if not PlayerState.spend_currency("jade", price):
		detail_label.text = "[b]Недостаточно нефрита[/b]"
		_refresh()
		return
	var currency_id := str(offer.get("currency", "gold"))
	var amount := int(offer.get("amount", 0))
	if currency_id == "breakthrough_stone":
		PlayerState.add_inventory_item("breakthrough_stone", amount, "epic")
		OnlineSyncService.queue_action("shop_purchase", {"offer_id": offer_id, "amount": amount, "currency_id": currency_id})
		detail_label.text = "[b]Покупка совершена[/b]\n\nПолучено: %s x%s" % [currency_id, str(amount)]
		_refresh()
		return
	PlayerState.add_currency(currency_id, amount)
	OnlineSyncService.queue_action("shop_purchase", {"offer_id": offer_id, "amount": amount, "currency_id": currency_id})
	detail_label.text = "[b]Покупка совершена[/b]\n\nПолучено: %s %s" % [str(amount), currency_id]
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
