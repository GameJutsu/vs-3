extends Node
## Sound Manager — Audio Effect Player
## Manages a pool of AudioStreamPlayers to play sound effects.
## Checks if sound files exist in `res://assets/sounds/` before playing to avoid crashes,
## allowing developers to drop sound assets in dynamically.

# --- SOUND FILE DICTIONARY ---
# Maps sound name keys to their expected file names in `res://assets/sounds/`
const SOUND_FILES: Dictionary = {
	"player_damage": "res://assets/sounds/player_damage.wav",
	"enemy_hit": "res://assets/sounds/enemy_hit.wav",
	"enemy_die": "res://assets/sounds/enemy_die.wav",
	"xp_collect": "res://assets/sounds/xp_collect.wav",
	"level_up": "res://assets/sounds/level_up.wav",
	"swap_companion": "res://assets/sounds/swap_companion.wav",
	"shoot_projectile": "res://assets/sounds/shoot_projectile.wav",
	"healer_pulse": "res://assets/sounds/healer_pulse.wav",
	"brawler_impact": "res://assets/sounds/brawler_impact.wav",
	"ui_hover": "res://assets/sounds/ui_hover.wav",
	"ui_click": "res://assets/sounds/ui_click.wav"
}

# --- INTERNAL STATE ---
var _loaded_sounds: Dictionary = {}
var _player_pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 16

func _ready() -> void:
	# Initialize the stream player pool to handle polyphony (concurrent sounds)
	for i in range(_pool_size):
		var player = AudioStreamPlayer.new()
		add_child(player)
		_player_pool.append(player)
		
	# Try loading sounds if files exist
	_load_existing_sound_assets()

# --- PUBLIC API ---
# Plays a sound effect by its name key
func play_sound(sound_name: String) -> void:
	if not _loaded_sounds.has(sound_name):
		# Try reload on-the-fly in case user just dropped it in
		_load_single_sound_asset(sound_name)
		if not _loaded_sounds.has(sound_name):
			return # Sound asset not present, fail silently

	var stream: AudioStream = _loaded_sounds[sound_name]
	var player: AudioStreamPlayer = _get_idle_player()
	
	if player != null:
		player.stream = stream
		player.play()

# --- INTERNAL HELPERS ---
func _load_existing_sound_assets() -> void:
	for sound_name in SOUND_FILES:
		_load_single_sound_asset(sound_name)

func _load_single_sound_asset(sound_name: String) -> void:
	if not SOUND_FILES.has(sound_name):
		return
	var path: String = SOUND_FILES[sound_name]
	
	if FileAccess.file_exists(path):
		var stream = load(path)
		if stream != null:
			_loaded_sounds[sound_name] = stream
			print("[SoundManager] Loaded audio asset: ", path)
	else:
		# Just print a warning on the first load check, don't crash
		pass

func _get_idle_player() -> AudioStreamPlayer:
	# Find a player that is not currently playing
	for player in _player_pool:
		if not player.playing:
			return player
	# If all are busy, steal the oldest one
	return _player_pool[0]
