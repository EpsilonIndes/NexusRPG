# GraphicsController.gd
extends Node

signal graphics_applied

var current_settings: Dictionary = {}

# cache
var cached_lights: Array[Light3D] = []
var cached_particles: Array[GPUParticles3D] = []
var cached_cameras: Array = []
var world_enviroment: WorldEnvironment = null

const PRESETS := {
	0: { # Bajo
		"shadows": 0,
		"lighting": false,
		"postprocess": 0,
		"particles": 0,
		"camera_shake": false
	},
	1: { # Medio
		"shadows": 1,
		"lighting": true,
		"postprocess": 1,
		"particles": 1,
		"camera_shake": true
	},
	2: { # Alto
		"shadows": 2,
		"lighting": true,
		"postprocess": 2,
		"particles": 2,
		"camera_shake": true
	},
	3: { # Ultra
		"shadows": 2,
		"lighting": true,
		"postprocess": 2,
		"particles": 2,
		"camera_shake": true
	}
}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	get_tree().tree_changed.connect(_rebuild_cache)
	_rebuild_cache()


# -----------
# API Pública
# -----------

func apply_graphics(new_settings: Dictionary) -> void:
	if current_settings == new_settings:
		return # Nada cambió

	var old_settings = current_settings
	current_settings = new_settings.duplicate(true)

	if old_settings.get("shadows") != new_settings.get("shadows"):
		_apply_shadows(new_settings["shadows"])

	if old_settings.get("lighting") != new_settings.get("lighting"):
		_apply_lighting(new_settings["lighting"])

	if old_settings.get("postprocess") != new_settings.get("postprocess"):
		_apply_postprocess(new_settings["postprocess"])

	if old_settings.get("particles") != new_settings.get("particles"):
		_apply_particles(new_settings["particles"])

	if old_settings.get("camera_shake") != new_settings.get("camera_shake"):
		_apply_camera_shake(new_settings["camera_shake"])

	graphics_applied.emit()


func reapply() -> void:
	if current_settings.is_empty():
		return
	
	apply_graphics(current_settings)


"""
Caché System

"""
func _rebuild_cache() -> void:
	cached_lights.clear()
	cached_particles.clear()
	cached_cameras.clear()
	world_enviroment = null

	for node in get_tree().get_nodes_in_group("dynamic_lights"):
		if node is Light3D:
			cached_lights.append(node)
	
	for node in get_tree().get_nodes_in_group("particles"):
		if node is GPUParticles3D:
			cached_particles.append(node)
	
	for node in get_tree().get_nodes_in_group("battle_camera"):
		cached_cameras.append(node)
	
	var envs = get_tree().get_nodes_in_group("world_enviroment")
	if envs.size() > 0:
		world_enviroment = envs[0]
	
	reapply()


func _on_node_added(node: Node) -> void:
	# Si se instancian en runetime, por ejemplo partículas de skill:
	if node.is_in_group("particles") and node is GPUParticles3D:
		cached_particles.append(node)
		_apply_particles(current_settings.get("particles", 2))


func apply_preset(level: int) -> Dictionary:
	if not PRESETS.has(level):
		return {}

	var preset_values = PRESETS[level].duplicate(true)

	# Construimos el nuevo settings completo
	var new_settings = preset_values.duplicate(true)
	new_settings["preset"] = level

	apply_graphics(new_settings)

	return new_settings

func detect_matching_preset(settings: Dictionary) -> int:
	for preset_level in PRESETS.keys():
		var preset_values = PRESETS[preset_level]
		
		var el_match := true
		for key in preset_values.keys():
			if settings.get(key) != preset_values[key]:
				el_match = false
				break
		
		if el_match:
			return preset_level

	return 4 # Personalizado

"""
-----------------
	Sombras
-----------------
0 Off
1 Basic
2 High
"""
func _apply_shadows(level: int) -> void:
	var enable_shadows := level > 0

	for light in get_tree().get_nodes_in_group("dynamic_lights"):
		if light is Light3D:
			light.shadow_enabled = enable_shadows
	
	match level:
		0:
			RenderingServer.directional_shadow_atlas_set_size(512, false)
		1:
			RenderingServer.directional_shadow_atlas_set_size(1024, false)
		2:
			RenderingServer.directional_shadow_atlas_set_size(2048, false)

# -------------------
#    Iluminación
# -------------------

func _apply_lighting(enabled: bool) -> void:
	for light in cached_lights:
		light.visible = enabled

"""
-------------------
   Postprocesado
-------------------
0 Off
1 Basic (Glow)
2 Full (Glow + Color Adjust)
"""
func _apply_postprocess(level: int) -> void:
	if not world_enviroment:
		return
	
	var env := world_enviroment.environment
	if not env:
		return
	
	env.glow_enabled = level > 0
	env.adjustment_enabled = level > 1


"""
-------------------
	Partículas
-------------------
0 Low
1 Medium
2 High
"""
func _apply_particles(level: int) -> void:
	var amount := 0
	match level:
		0: amount = 20
		1: amount = 80
		2: amount = 200
	
	for p in cached_particles:
		p.amount = amount

"""
------------------
   Camera Shake
------------------
"""
func _apply_camera_shake(enabled: bool) -> void:
	for cam in cached_cameras:
		if cam.has_method("set_shake_enabled"):
			cam.set_shake_enabled(enabled)

"""
------------------------
   Utilidades internas
------------------------
"""

func _find_world_enviroment() -> void:
	var candidates = get_tree().get_nodes_in_group("world_enviroment")
	if candidates.size() > 0:
		world_enviroment = candidates[0]
