extends RefCounted

static var _cache: Dictionary = {}

const ICON_PATHS := {
	"spirit_stone": "res://assets/ui/icons/spirit_stone.b64",
	"bound_spirit_stone": "res://assets/ui/icons/bound_spirit_stone.b64",
	"jade": "res://assets/ui/icons/jade.b64",
	"azure_slash": "res://assets/ui/icons/azure_slash.b64",
	"jade_guard": "res://assets/ui/icons/jade_guard.b64"
}

static func get_icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var path := str(ICON_PATHS.get(id, ""))
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var encoded := file.get_as_text().strip_edges()
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		return null
	var image := Image.new()
	var err := image.load_webp_from_buffer(bytes)
	if err != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_cache[id] = texture
	return texture

static func get_currency_icon(currency_id: String) -> Texture2D:
	match currency_id:
		"spirit_stone":
			return get_icon("spirit_stone")
		"bound_spirit_stone":
			return get_icon("bound_spirit_stone")
		"jade":
			return get_icon("jade")
		_:
			return null

static func get_skill_icon(skill_id: String) -> Texture2D:
	match skill_id:
		"azure_slash":
			return get_icon("azure_slash")
		"jade_guard":
			return get_icon("jade_guard")
		"soul_bloom":
			return get_icon("jade")
		_:
			return get_icon("azure_slash")

static func get_item_icon(item_id: String) -> Texture2D:
	match item_id:
		"jade_sword_01":
			return get_icon("azure_slash")
		"breakthrough_stone":
			return get_icon("spirit_stone")
		"qi_pill_small":
			return get_icon("jade")
		_:
			return get_icon("spirit_stone")
