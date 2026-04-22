extends Node

const STORY_SWEEP_STAMINA_COST := 4
const EVENT_DUNGEON_MAX_RUNS_PER_DAY := 3
const EVENT_DUNGEON_STAMINA_COST := 8
const GUILD_BOSS_MAX_RUNS_PER_WEEK := 2
const GUILD_BOSS_STAMINA_COST := 10
const ARENA_MAX_RUNS_PER_DAY := 5
const SEASON_PASS_XP_PER_LEVEL := 100
const SEASON_PASS_MAX_LEVEL := 30

var is_initialized: bool = false
var last_battle_result: Dictionary = {}
var claimed_daily_missions: Dictionary = {}
var pending_battle_context: Dictionary = {}
var current_daily_key: String = ""
var current_weekly_key: String = ""
var event_dungeon_runs_used: Dictionary = {}
var guild_boss_runs_used: Dictionary = {}
var arena_runs_used: int = 0
var season_pass_xp: int = 0
var season_pass_claimed: Dictionary = {}

func initialize() -> void:
	if is_initialized:
		return
	ConfigRepository.load_all()
	PlayerState.load_or_create_profile()
	IdleRewardService.mark_exit_time()
	current_daily_key = _today_key_utc()
	current_weekly_key = _weekly_key_utc()
	_apply_daily_reset_if_needed()
	_apply_weekly_reset_if_needed()
	_ensure_system_mail_generated()
	is_initialized = true

func _today_key_utc() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(now.get("year", 1970)), int(now.get("month", 1)), int(now.get("day", 1))]

func _weekly_key_utc() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-W%02d" % [int(now.get("year", 1970)), int(now.get("weekday", 1))]

func _cycle_day_index() -> int:
	return int(floor(float(Time.get_unix_time_from_system()) / 86400.0))

func _apply_daily_reset_if_needed() -> void:
	var today := _today_key_utc()
	if current_daily_key == "":
		current_daily_key = today
	if current_daily_key == today:
		return
	claimed_daily_missions.clear()
	event_dungeon_runs_used.clear()
	arena_runs_used = 0
	current_daily_key = today
	_ensure_system_mail_generated()

func _apply_weekly_reset_if_needed() -> void:
	var week_key := _weekly_key_utc()
	if current_weekly_key == "":
		current_weekly_key = week_key
	if current_weekly_key == week_key:
		return
	guild_boss_runs_used.clear()
	season_pass_xp = 0
	season_pass_claimed.clear()
	current_weekly_key = week_key

func _ensure_system_mail_generated() -> void:
	var daily_key := "daily_supply_%s" % current_daily_key
	if not PlayerState.has_generated_mail_key(daily_key):
		PlayerState.add_inbox_message({
			"id": daily_key,
			"title": "Ежедневные припасы",
			"from": "Небесная канцелярия",
			"body": "Сегодняшний путь благосклонен. Забери ежедневные припасы культиватора.",
			"claimed": false,
			"rewards": {"gold": 1200, "bound_spirit_stone": 40, "items": [{"id": "stamina_pill_small", "quantity": 1, "rarity": "rare"}]}
		})
		PlayerState.mark_generated_mail_key(daily_key)
	var banner_state := get_banner_live_state("default_banner")
	var banner_key := "banner_notice_%s_%s" % [current_daily_key, str(banner_state.get("cycle", 0))]
	if not PlayerState.has_generated_mail_key(banner_key):
		PlayerState.add_inbox_message({
			"id": banner_key,
			"title": "Сводка ротации баннера",
			"from": "Архив духовных знамений",
			"body": "Цикл баннера обновлён. Проверь текущую ротацию редких призывов и предложения дня.",
			"claimed": false,
			"rewards": {"jade": 5, "stamina": 6}
		})
		PlayerState.mark_generated_mail_key(banner_key)

func refresh_live_ops_state() -> void:
	_apply_daily_reset_if_needed()
	_apply_weekly_reset_if_needed()

func get_daily_reset_status() -> Dictionary:
	_apply_daily_reset_if_needed()
	_apply_weekly_reset_if_needed()
	var now := Time.get_unix_time_from_system()
	var seconds_until_reset := 86400 - int(now % 86400)
	return {
		"daily_key": current_daily_key,
		"weekly_key": current_weekly_key,
		"seconds_until_reset": seconds_until_reset,
		"shop_cycle": _cycle_day_index() % 3,
		"banner_cycle": _cycle_day_index() % 2,
		"event_cycle": _cycle_day_index() % 3
	}

func get_shop_offer_state(offer_id: String) -> Dictionary:
	var live_ops := get_daily_reset_status()
	var cycle := int(live_ops.get("shop_cycle", 0))
	var enabled := true
	if offer_id.contains("breakthrough"):
		enabled = cycle != 1
	elif offer_id.contains("jade"):
		enabled = cycle != 2
	return {"enabled": enabled, "cycle": cycle}

func get_banner_live_state(banner_id: String) -> Dictionary:
	var live_ops := get_daily_reset_status()
	var cycle := int(live_ops.get("banner_cycle", 0))
	return {"featured": cycle == 0, "cycle": cycle, "banner_id": banner_id}

func get_event_dungeon_state() -> Dictionary:
	_apply_daily_reset_if_needed()
	var live_ops := get_daily_reset_status()
	var cycle := int(live_ops.get("event_cycle", 0))
	var titles := ["Пещера духовных жил", "Алтарь небесной молнии", "Дворец алой печати"]
	var enemy_names := ["Хранитель жилы", "Грозовой экзарх", "Повелитель алой печати"]
	var event_id := "event_dungeon_%d" % cycle
	var used := int(event_dungeon_runs_used.get(event_id, 0))
	return {"event_id": event_id, "cycle": cycle, "title": titles[min(cycle, titles.size() - 1)], "enemy_name": enemy_names[min(cycle, enemy_names.size() - 1)], "max_runs": EVENT_DUNGEON_MAX_RUNS_PER_DAY, "used_runs": used, "remaining_runs": max(EVENT_DUNGEON_MAX_RUNS_PER_DAY - used, 0), "stamina_cost": EVENT_DUNGEON_STAMINA_COST, "active": true}

func can_enter_event_dungeon() -> bool:
	return int(get_event_dungeon_state().get("remaining_runs", 0)) > 0

func begin_event_dungeon_run() -> Dictionary:
	var state := get_event_dungeon_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		return {"ok": false, "text": "Попытки события на сегодня закончились"}
	if not PlayerState.spend_stamina(EVENT_DUNGEON_STAMINA_COST):
		return {"ok": false, "text": "Недостаточно энергии для ивент-подземелья"}
	var event_id := str(state.get("event_id", "event_dungeon_0"))
	event_dungeon_runs_used[event_id] = int(event_dungeon_runs_used.get(event_id, 0)) + 1
	return {"ok": true, "event_id": event_id, "stamina_cost": EVENT_DUNGEON_STAMINA_COST, "remaining_runs": max(int(state.get("remaining_runs", 0)) - 1, 0)}

func get_event_dungeon_rewards(victory: bool) -> Dictionary:
	var state := get_event_dungeon_state()
	var cycle := int(state.get("cycle", 0))
	if not victory:
		return {"gold": 120, "qi_essence": 10, "spirit_stone": 0, "jade": 0, "items": []}
	var items: Array = [{"id": "qi_pill_small", "quantity": 2 + cycle, "rarity": "rare"}]
	if cycle >= 1:
		items.append({"id": "stamina_pill_small", "quantity": 1, "rarity": "rare"})
	if cycle >= 2:
		items.append({"id": "breakthrough_stone", "quantity": 1, "rarity": "epic"})
	return {"gold": 900 + cycle * 280, "qi_essence": 75 + cycle * 24, "spirit_stone": 2 + cycle, "jade": 6 + cycle * 2, "items": items}

func get_guild_boss_state() -> Dictionary:
	_apply_weekly_reset_if_needed()
	var cycle := _cycle_day_index() % 3
	var boss_names := ["Дракон небесной меди", "Пожиратель нефрита", "Владыка расколотой печати"]
	var boss_id := "guild_boss_%d" % cycle
	var used := int(guild_boss_runs_used.get(boss_id, 0))
	var progress := min(used * 35, 100)
	return {"boss_id": boss_id, "cycle": cycle, "name": boss_names[min(cycle, boss_names.size() - 1)], "max_runs": GUILD_BOSS_MAX_RUNS_PER_WEEK, "used_runs": used, "remaining_runs": max(GUILD_BOSS_MAX_RUNS_PER_WEEK - used, 0), "stamina_cost": GUILD_BOSS_STAMINA_COST, "progress": progress, "boss_ready": true}

func begin_guild_boss_run() -> Dictionary:
	var state := get_guild_boss_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		return {"ok": false, "text": "Попытки босса ордена на этой неделе закончились"}
	if not PlayerState.spend_stamina(GUILD_BOSS_STAMINA_COST):
		return {"ok": false, "text": "Недостаточно энергии для босса ордена"}
	var boss_id := str(state.get("boss_id", "guild_boss_0"))
	guild_boss_runs_used[boss_id] = int(guild_boss_runs_used.get(boss_id, 0)) + 1
	return {"ok": true, "boss_id": boss_id, "stamina_cost": GUILD_BOSS_STAMINA_COST, "remaining_runs": max(int(state.get("remaining_runs", 0)) - 1, 0), "progress": min((int(state.get("used_runs", 0)) + 1) * 35, 100)}

func get_guild_boss_rewards(victory: bool) -> Dictionary:
	var state := get_guild_boss_state()
	var cycle := int(state.get("cycle", 0))
	if not victory:
		return {"gold": 180, "qi_essence": 20, "spirit_stone": 0, "jade": 0, "items": []}
	var items: Array = [{"id": "qi_pill_small", "quantity": 3 + cycle, "rarity": "rare"}, {"id": "breakthrough_stone", "quantity": 1, "rarity": "epic"}]
	if cycle >= 1:
		items.append({"id": "stamina_pill_small", "quantity": 1, "rarity": "rare"})
	return {"gold": 1400 + cycle * 420, "qi_essence": 120 + cycle * 30, "spirit_stone": 4 + cycle, "jade": 10 + cycle * 3, "items": items}

func get_arena_state() -> Dictionary:
	_apply_daily_reset_if_needed()
	var power := PlayerState.get_power()
	var opponents: Array = [
		{"name": "Лорд Белых Облаков", "power": max(power - 180, 1200), "rank": 128},
		{"name": "Тень Нефритовой Башни", "power": power + 90, "rank": 103},
		{"name": "Копьё Небесной Пыли", "power": power + 260, "rank": 87}
	]
	return {"remaining_runs": max(ARENA_MAX_RUNS_PER_DAY - arena_runs_used, 0), "max_runs": ARENA_MAX_RUNS_PER_DAY, "opponents": opponents, "season_rating": 1200 + arena_runs_used * 18}

func begin_arena_run(opponent_index: int) -> Dictionary:
	var state := get_arena_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		return {"ok": false, "text": "Лимит арены на сегодня исчерпан"}
	var opponents: Array = state.get("opponents", [])
	if opponent_index < 0 or opponent_index >= opponents.size():
		return {"ok": false, "text": "Соперник не найден"}
	arena_runs_used += 1
	return {"ok": true, "remaining_runs": max(int(state.get("remaining_runs", 0)) - 1, 0), "opponent": opponents[opponent_index]}

func get_arena_rewards(victory: bool) -> Dictionary:
	if not victory:
		return {"gold": 150, "qi_essence": 12, "spirit_stone": 0, "jade": 1, "items": []}
	return {"gold": 520, "qi_essence": 42, "spirit_stone": 1, "jade": 4, "items": [{"id": "qi_pill_small", "quantity": 1, "rarity": "rare"}]}

func award_season_pass_xp(amount: int, source: String = "activity") -> Dictionary:
	if amount <= 0:
		return get_season_pass_state()
	season_pass_xp = min(season_pass_xp + amount, SEASON_PASS_MAX_LEVEL * SEASON_PASS_XP_PER_LEVEL)
	return get_season_pass_state()

func get_season_pass_state() -> Dictionary:
	_apply_weekly_reset_if_needed()
	var level := min(int(floor(float(season_pass_xp) / float(SEASON_PASS_XP_PER_LEVEL))) + 1, SEASON_PASS_MAX_LEVEL)
	var xp_in_level := season_pass_xp % SEASON_PASS_XP_PER_LEVEL
	return {"level": level, "xp_total": season_pass_xp, "xp_in_level": xp_in_level, "xp_needed": SEASON_PASS_XP_PER_LEVEL, "max_level": SEASON_PASS_MAX_LEVEL, "claimed": season_pass_claimed}

func get_season_pass_reward_preview(level: int) -> Dictionary:
	return {"gold": 300 + level * 40, "jade": 2 + int(level / 5), "bound_spirit_stone": 20 + level * 3}

func claim_season_pass_reward(level: int) -> Dictionary:
	var pass_state := get_season_pass_state()
	if level > int(pass_state.get("level", 1)):
		return {"ok": false, "text": "Уровень пропуска ещё не достигнут"}
	if bool(season_pass_claimed.get(str(level), false)):
		return {"ok": false, "text": "Награда уровня уже забрана"}
	var reward := get_season_pass_reward_preview(level)
	PlayerState.add_currency("gold", int(reward.get("gold", 0)))
	PlayerState.add_currency("jade", int(reward.get("jade", 0)))
	PlayerState.add_currency("bound_spirit_stone", int(reward.get("bound_spirit_stone", 0)))
	season_pass_claimed[str(level)] = true
	return {"ok": true, "level": level, "reward": reward, "text": "Награда season pass получена"}

func has_claimed_story_reward(node_id: String) -> bool:
	return PlayerState.has_claimed_story_reward(node_id)

func mark_story_reward_claimed(node_id: String) -> void:
	PlayerState.mark_story_reward_claimed(node_id)

func has_claimed_daily_mission(mission_id: String) -> bool:
	_apply_daily_reset_if_needed()
	return bool(claimed_daily_missions.get(mission_id, false))

func mark_daily_mission_claimed(mission_id: String) -> void:
	_apply_daily_reset_if_needed()
	claimed_daily_missions[mission_id] = true

func set_battle_context(context: Dictionary) -> void:
	pending_battle_context = context

func get_battle_context() -> Dictionary:
	return pending_battle_context

func clear_battle_context() -> void:
	pending_battle_context = {}

func has_claimed_battle_rewards() -> bool:
	return bool(last_battle_result.get("claimed", false))

func has_completed_story_battle(node_id: String) -> bool:
	return PlayerState.has_completed_story_battle(node_id)

func is_story_chapter_unlocked(chapter_id: String) -> bool:
	return PlayerState.is_story_chapter_unlocked(chapter_id)

func mark_story_battle_completed(node_id: String, chapter_id: String, stars: int = 1) -> void:
	PlayerState.mark_story_battle_completed(node_id)
	PlayerState.set_story_battle_stars(node_id, stars)
	var next_id := _next_chapter_id(chapter_id)
	if not next_id.is_empty():
		PlayerState.unlock_story_chapter(next_id)

func _next_chapter_id(chapter_id: String) -> String:
	var chapters := ConfigRepository.story.get("chapters", [])
	for i in range(chapters.size()):
		if str(chapters[i].get("id", "")) == chapter_id and i + 1 < chapters.size():
			return str(chapters[i + 1].get("id", ""))
	return ""

func _story_node_multiplier(node_type: String) -> float:
	match node_type:
		"elite_battle":
			return 1.45
		"boss_battle":
			return 1.9
		_:
			return 1.0

func get_story_sweep_cost(node_type: String = "battle") -> int:
	match node_type:
		"elite_battle":
			return STORY_SWEEP_STAMINA_COST + 2
		"boss_battle":
			return STORY_SWEEP_STAMINA_COST + 4
		_:
			return STORY_SWEEP_STAMINA_COST

func _build_story_rewards(chapter_index: int, node_type: String = "battle", victory: bool = true) -> Dictionary:
	var mult := _story_node_multiplier(node_type)
	var gold := int(floor(((320 if victory else 80) + (chapter_index - 1) * 140) * mult))
	var qi_essence := int(floor(((18 if victory else 6) + (chapter_index - 1) * 8) * mult))
	var spirit_stone := int(floor(((1 if victory else 0) + (1 if victory and chapter_index >= 3 else 0)) * mult))
	var items: Array = []
	if victory:
		items.append({"id": "qi_pill_small", "quantity": max(1, int(floor((1 + int(chapter_index >= 2)) * mult))), "rarity": "rare"})
		if node_type == "elite_battle":
			items.append({"id": "stamina_pill_small", "quantity": 1, "rarity": "rare"})
		if chapter_index >= 3 or node_type == "boss_battle":
			items.append({"id": "breakthrough_stone", "quantity": 1 if node_type != "boss_battle" else 2, "rarity": "epic"})
	return {"gold": gold, "qi_essence": qi_essence, "spirit_stone": spirit_stone, "items": items}

func _star_multiplier(stars: int) -> float:
	match clamp(stars, 1, 3):
		1:
			return 0.6
		2:
			return 0.85
		_:
			return 1.0

func _scaled_story_rewards(chapter_index: int, stars: int, node_type: String = "battle") -> Dictionary:
	var base := _build_story_rewards(chapter_index, node_type, true)
	var mult := _star_multiplier(stars)
	var scaled_items: Array = []
	for item in base.get("items", []):
		var qty := max(1, int(floor(float(int(item.get("quantity", 1))) * mult)))
		scaled_items.append({"id": item.get("id", ""), "quantity": qty, "rarity": item.get("rarity", "rare")})
	return {"gold": int(floor(float(int(base.get("gold", 0))) * mult)), "qi_essence": int(floor(float(int(base.get("qi_essence", 0))) * mult)), "spirit_stone": int(floor(float(int(base.get("spirit_stone", 0))) * mult)), "items": scaled_items}

func _grant_rewards(rewards: Dictionary) -> void:
	PlayerState.add_currency("gold", int(rewards.get("gold", 0)))
	PlayerState.add_currency("bound_spirit_stone", int(rewards.get("qi_essence", 0)))
	PlayerState.add_currency("spirit_stone", int(rewards.get("spirit_stone", 0)))
	PlayerState.add_currency("jade", int(rewards.get("jade", 0)))
	for item in rewards.get("items", []):
		PlayerState.add_inventory_item(str(item.get("id", "")), int(item.get("quantity", 1)), str(item.get("rarity", "rare")))

func perform_story_sweep(chapter_id: String, node_id: String, chapter_index: int, enemy_name: String, node_type: String = "battle") -> Dictionary:
	if not has_completed_story_battle(node_id):
		return {"ok": false, "text": "Сначала нужно пройти этот бой вручную"}
	var stamina_cost := get_story_sweep_cost(node_type)
	if not PlayerState.spend_stamina(stamina_cost):
		return {"ok": false, "text": "Недостаточно энергии для быстрого фарма"}
	var stars := max(PlayerState.get_story_battle_stars(node_id), 1)
	var rewards := _scaled_story_rewards(chapter_index, stars, node_type)
	_grant_rewards(rewards)
	return {"ok": true, "chapter_id": chapter_id, "node_id": node_id, "chapter_index": chapter_index, "enemy_name": enemy_name, "node_type": node_type, "stars": stars, "stamina_spent": stamina_cost, "runs": 1, "rewards": rewards, "text": "Быстрый проход выполнен"}

func perform_multi_story_sweep(chapter_id: String, node_id: String, chapter_index: int, enemy_name: String, runs: int, node_type: String = "battle") -> Dictionary:
	if runs <= 0:
		return {"ok": false, "text": "Некорректное число проходов"}
	if not has_completed_story_battle(node_id):
		return {"ok": false, "text": "Сначала нужно пройти этот бой вручную"}
	var total_cost := get_story_sweep_cost(node_type) * runs
	if not PlayerState.spend_stamina(total_cost):
		return {"ok": false, "text": "Недостаточно энергии для серии проходов"}
	var stars := max(PlayerState.get_story_battle_stars(node_id), 1)
	var total_rewards := {"gold": 0, "qi_essence": 0, "spirit_stone": 0, "jade": 0, "items": []}
	for i in range(runs):
		var rewards := _scaled_story_rewards(chapter_index, stars, node_type)
		total_rewards["gold"] = int(total_rewards.get("gold", 0)) + int(rewards.get("gold", 0))
		total_rewards["qi_essence"] = int(total_rewards.get("qi_essence", 0)) + int(rewards.get("qi_essence", 0))
		total_rewards["spirit_stone"] = int(total_rewards.get("spirit_stone", 0)) + int(rewards.get("spirit_stone", 0))
		total_rewards["jade"] = int(total_rewards.get("jade", 0)) + int(rewards.get("jade", 0))
		for item in rewards.get("items", []):
			total_rewards["items"].append(item)
	_grant_rewards(total_rewards)
	return {"ok": true, "chapter_id": chapter_id, "node_id": node_id, "chapter_index": chapter_index, "enemy_name": enemy_name, "node_type": node_type, "stars": stars, "stamina_spent": total_cost, "runs": runs, "rewards": total_rewards, "text": "Серия быстрых проходов выполнена"}

func perform_story_auto_farm(chapter_id: String, node_id: String, chapter_index: int, enemy_name: String, node_type: String = "battle") -> Dictionary:
	var stamina := PlayerState.refresh_stamina()
	var available_runs := int(stamina.get("current", 0)) / get_story_sweep_cost(node_type)
	available_runs = min(available_runs, 5)
	if available_runs <= 0:
		return {"ok": false, "text": "Недостаточно энергии для автофарма"}
	return perform_multi_story_sweep(chapter_id, node_id, chapter_index, enemy_name, available_runs, node_type)

func _season_pass_xp_for_context(context: Dictionary, victory: bool) -> int:
	if not victory:
		return 5
	match str(context.get("source", "")):
		"event_dungeon":
			return 28
		"guild_boss":
			return 40
		"arena":
			return 22
		"story":
			return 16
		_:
			return 10

func claim_last_battle_rewards() -> Dictionary:
	if has_claimed_battle_rewards():
		return last_battle_result.get("rewards", {})
	var rewards := last_battle_result.get("rewards", {})
	_grant_rewards(rewards)
	var context := last_battle_result.get("context", {})
	award_season_pass_xp(_season_pass_xp_for_context(context, bool(last_battle_result.get("victory", false))), str(context.get("source", "battle")))
	if bool(last_battle_result.get("victory", false)):
		if str(context.get("source", "")) == "story":
			mark_story_battle_completed(str(context.get("node_id", "")), str(context.get("chapter_id", "")), int(last_battle_result.get("stars", 1)))
	last_battle_result["claimed"] = true
	return rewards
