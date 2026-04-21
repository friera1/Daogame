extends RefCounted

static func load_texture_safe(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	return load(path) as Texture2D
