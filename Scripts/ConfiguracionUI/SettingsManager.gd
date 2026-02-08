"(Autoload)"

extends Node

const SETTINGS_PATH: String= "user://settings.cfg"
const SETTINGS_VERSION: int = 1

const DEFAULT_SETTINGS: Dictionary = {
	"audio": {
		"master": 1.0,
		"music": 0.8,
		"sfx": 0.9,
		"voices": 1.0
	},
	"video": {
		"display_mode": 1,
		"resolution": 0,
		"vsync": true,
		"scaling": 0
	},
	"gameplay": {
		"text_speed": 1.0,
		"auto_advance": false
	}
}

const RESOLUTIONS := [
	Vector2i(640, 480),
	Vector2i(960, 540),
	Vector2i(1024, 680),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var settings : Dictionary = DEFAULT_SETTINGS.duplicate(true)


func _ready():
	load_settings()
	apply_all()

func apply_all():
	apply_audio()
	apply_video()
	apply_gameplay()

func reset_to_defaults():
	settings = DEFAULT_SETTINGS.duplicate(true)

func load_settings():
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	for category in settings.keys():
		for key in settings[category].keys():
			if cfg.has_section_key(category, key):
				settings[category][key] = cfg.get_value(category, key)

func save_settings():
	var cfg := ConfigFile.new()

	for category in settings.keys():
		for key in settings[category].keys():
			cfg.set_value(category, key, settings[category][key])

	cfg.set_value("meta", "version", SETTINGS_VERSION)
	cfg.save(SETTINGS_PATH)

func apply_audio():
	_set_bus("Master", settings.audio.master)
	_set_bus("Music", settings.audio.music)
	_set_bus("SFX", settings.audio.sfx)
	_set_bus("Voices", settings.audio.voices)

func _set_bus(bus_name: String, value: float):
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func apply_video():
	var video = settings.get("video", {})
	var display_mode = video.get("display_mode", 0)
	match video.get("display_mode", 0):
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# --- Resolution (Solo si no es fullscreen exclusivo)
	if display_mode == 0:
		var res_index = video.get("resolution", 0)
		if res_index >= 0 and res_index < RESOLUTIONS.size():
			var res: Vector2i = RESOLUTIONS[res_index]
			DisplayServer.window_set_size(res)
			DisplayServer.window_set_position(
				DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() - res) / 2) # Centrado
	
	# --- VSync
	var vsync_enabled = video.get("vsync", true)
	if vsync_enabled:
		print("Vsync enabled")
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	# --- Scaling (Si se usa stretch)
	_apply_scaling(video.get("scaling", 0))
	
	await get_tree().process_frame

func _apply_scaling(mode: int):
	var root := get_tree().root

	match mode:
		0: # Pixel perfect / integer
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			root.content_scale_factor = 1.0
		1: # Stretch
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


func apply_gameplay():
	# placeholder
	pass



# --- Helpers
func get_setting(category: String, key: String):
	return settings.get(category, {}).get(key)

func set_setting(category: String, key: String, value):
	if settings.has(category) and settings[category].has(key):
		settings[category][key] = value


"""
ENUMERACIONES MENTALES

# display_mode
0 = Windowed
1 = Fullscreen (borderless)
# (2 = Exclusive fullscreen → futuro)

# scaling
0 = Pixel perfect / integer
1 = Stretch

"""
