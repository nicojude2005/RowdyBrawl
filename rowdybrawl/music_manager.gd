extends Node2D

const level1HeavyTheme = preload("uid://dlo8imfn8cbid")
const level1CalmTheme = preload("uid://cjkjw7akh2n8l")

@onready var calm_track: AudioStreamPlayer2D = $calmTrack
@onready var heavy_track: AudioStreamPlayer2D = $HeavyTrack
@onready var song_fader: AnimationPlayer = $songFader

var trackTime : float = 0
var inCombat : bool = false

func _ready() -> void:
	calm_track.stream = level1CalmTheme
	heavy_track.stream = level1HeavyTheme

func _process(delta: float) -> void:
	if inCombat:
		trackTime += delta * heavy_track.pitch_scale
	else:
		trackTime += delta * calm_track.pitch_scale
	
	if Input.is_action_just_pressed("debug"):
		swapSongs()
	
func swapSongs():
	if inCombat:
		calm_track.play(trackTime)
		song_fader.play("fadeToCalm")
		inCombat = false
	else:
		heavy_track.play(trackTime)
		song_fader.play("fadeToCombat")
		inCombat = true

func loopSongs():
	trackTime = 0
	if inCombat:
		heavy_track.play(0)
	else:
		calm_track.play(0)


func _on_calm_track_finished() -> void:
	loopSongs()

func _on_heavy_track_finished() -> void:
	loopSongs()
