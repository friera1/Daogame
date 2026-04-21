extends Control

@onready var banner_label: Label = %BannerLabel
@onready var info_label: RichTextLabel = %InfoLabel

var current_banner: Dictionary = {}
var pity_counter := 0

func _ready() -> void:
	var banners := ConfigRepository.summon_pools.get("banners", [])
	if banners.size() > 0:
		current_banner = banners[0]
		banner_label.text = str(current_banner.get("title", "Призыв"))
		_refresh_info("Готов к призыву")

func _refresh_info(message: String) -> void:
	info_label.text = "[b]%s[/b]\n\nВалюта: %s\nЦена: %s\nPity: %d / %d" % [
		message,
		str(current_banner.get("currency", "jade")),
		str(current_banner.get("cost_per_pull", 10)),
		pity_counter,
		int(current_banner.get("pity", 30))
	]

func _on_pull_once_pressed() -> void:
	var cost := int(current_banner.get("cost_per_pull", 10))
	if not PlayerState.spend_currency(str(current_banner.get("currency", "jade")), cost):
		_refresh_info("Недостаточно валюты для призыва")
		return
	pity_counter += 1
	var reward := _resolve_reward()
	_refresh_info("Получено: %s" % reward)

func _resolve_reward() -> String:
	var pool := current_banner.get("pool", [])
	if pity_counter >= int(current_banner.get("pity", 30)) and pool.size() > 0:
		pity_counter = 0
		return str(pool[0].get("id", "reward"))
	if pool.size() == 0:
		return "пусто"
	var index := randi() % pool.size()
	return str(pool[index].get("id", "reward"))

func _on_pull_ten_pressed() -> void:
	for i in range(10):
		_on_pull_once_pressed()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
