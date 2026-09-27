@tool
extends Control
## Representación reutilizable; no aplica efectos ni modifica estadísticas.
## Busca <stat>_.png en icon_directory, por ejemplo hp_.png o def_.png.

const FALLBACK_ICON: Texture2D = preload("res://Assets/UIX/Stats/stat_default.png")
const STAT_ALIASES := {
	"hp_max": "hp", "max_hp": "hp", "vida": "hp",
	"ataque": "atk", "defensa": "def", "velocidad": "spd",
	"suerte": "lck", "espiritu": "wis", "precision": "prec",
	"evasion": "eva"
}
enum Indicator { NONE, BUFF, DEBUFF }

@export var stat_name: String = "":
	set(value):
		stat_name = value
		_resolve_stat_texture()
@export_dir var icon_directory: String = "res://Assets/UIX/Stats":
	set(value):
		icon_directory = value
		_resolve_stat_texture()
## Override opcional: tiene prioridad sobre la búsqueda por nombre.
@export var stat_texture: Texture2D:
	set(value):
		stat_texture = value
		_refresh()
@export var indicator_texture: Texture2D = preload("res://Assets/UIX/Stats/flecha_indicador.png"):
	set(value):
		indicator_texture = value
		_refresh()
@export var indicator: Indicator = Indicator.NONE:
	set(value):
		indicator = value
		_refresh()

var _resolved_texture: Texture2D

func _ready() -> void:
	$Indicator.resized.connect(_center_indicator)
	_resolve_stat_texture()
	_center_indicator()

func configure(texture: Texture2D, direction: Indicator = Indicator.NONE) -> void:
	stat_texture = texture
	stat_name = ""
	indicator = direction

func configure_stat(key: String, direction: Indicator = Indicator.NONE) -> void:
	stat_texture = null
	stat_name = key
	indicator = direction

func _resolve_stat_texture() -> void:
	var key := stat_name.strip_edges().to_lower().trim_suffix("_")
	key = str(STAT_ALIASES.get(key, key))
	_resolved_texture = null
	# Sólo nombres de stat, nunca rutas proporcionadas por el llamador.
	if not key.is_empty() and key.is_valid_identifier():
		var path := icon_directory.path_join(key + "_.png")
		if ResourceLoader.exists(path, "Texture2D"):
			_resolved_texture = load(path) as Texture2D
	_refresh()

func _center_indicator() -> void:
	$Indicator.pivot_offset = $Indicator.size * 0.5

func _refresh() -> void:
	if not is_node_ready():
		return
	$Stat.texture = stat_texture if stat_texture != null else _resolved_texture
	if $Stat.texture == null:
		$Stat.texture = FALLBACK_ICON
	$Indicator.texture = indicator_texture
	$Indicator.visible = indicator != Indicator.NONE and indicator_texture != null
	$Indicator.rotation = PI if indicator == Indicator.DEBUFF else 0.0
	$Indicator.material.set_shader_parameter("is_debuff", indicator == Indicator.DEBUFF)
	_center_indicator()
