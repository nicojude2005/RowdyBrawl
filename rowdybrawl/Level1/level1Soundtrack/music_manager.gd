extends Node2D
class_name musicManager

@export var level1HeavyTheme = preload("uid://cwghue4p251pi")
@export var level1CalmTheme =  preload("uid://cmmdbtwmwvq7x")

@export var isMenu = false #THIS IS A WORKAROUND, KINDA SLOPPY BUT IT WORKS

@onready var calm_track: AudioStreamPlayer2D = $calmTrack
@onready var heavy_track: AudioStreamPlayer2D = $HeavyTrack
@onready var song_fader: AnimationPlayer = $songFader

var trackTime : float = 0
var inCombat : bool = false

func _ready() -> void:
	calm_track.stream = level1CalmTheme
	heavy_track.stream = level1HeavyTheme
	
	if !isMenu:
		calm_track.volume_db = -6
		calm_track.pitch_scale = .9
	else:
		calm_track.volume_db = 0
		calm_track.pitch_scale = 1
	calm_track.play()

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

func setCombatTrack(toCombat: bool):
	if !inCombat and toCombat:
		swapSongs()
	elif inCombat and !toCombat:
		swapSongs()

func _on_calm_track_finished() -> void:
	if trackTime >= 1:
		loopSongs()
func _on_heavy_track_finished() -> void:
	if trackTime >= 1:
		loopSongs()
