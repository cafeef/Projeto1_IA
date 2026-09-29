extends Node
## Autoload "Voz": lê frases em voz alta.
##
## Prioridade: gravações em res://audio/voz/<id>.ogg|.mp3|.wav (voz humana ou
## neural, ver audio/README.md). Se faltar alguma gravação da frase pedida,
## usa a voz do sistema (texto para fala), que em alguns computadores soa
## robótica. Os textos ficam em res://audio/frases.json.

const DIR := "res://audio/voz/"
const EXTENSIONS := ["ogg", "mp3", "wav"]
## Vozes de sistema mais naturais, na ordem de preferência.
const PREFERRED := ["Francisca", "Thalita", "Maria", "Luciana", "Google", "Microsoft", "Daniel"]

var frases := {}
var _player: AudioStreamPlayer
var _queue: Array = []


func _ready() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://audio/frases.json"))
	if typeof(data) == TYPE_DICTIONARY:
		frases = data
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_play_next)


func text(id: String) -> String:
	return frases.get(id, id)


func has_clip(id: String) -> bool:
	return _clip_path(id) != ""


## Fala uma sequência de frases (ids de frases.json). Textos que não são ids
## (fases criadas no editor) vão direto para a voz do sistema.
## system_fallback=false: sem gravação, fica em silêncio (usado nas falas
## automáticas, para não tocar a voz robótica sem a criança pedir).
func say(ids: Array, system_fallback := true) -> void:
	stop()
	var all_recorded := ids.all(func(id): return has_clip(id))
	if all_recorded:
		_queue = ids.duplicate()
		_play_next()
	elif system_fallback:
		var parts := PackedStringArray()
		for id in ids:
			parts.append(text(id))
		_system_say(" ".join(parts))


func stop() -> void:
	_queue.clear()
	if _player:
		_player.stop()
	if _system_voice() != "":
		DisplayServer.tts_stop()


func _play_next() -> void:
	if _queue.is_empty():
		return
	var stream = load(_clip_path(_queue.pop_front()))
	if stream is AudioStream:
		_player.stream = stream
		_player.play()
	else:
		_play_next()


func _clip_path(id: String) -> String:
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [DIR, id, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


func _system_say(message: String) -> void:
	var voice := _system_voice()
	if voice != "":
		DisplayServer.tts_speak(message, voice, 80, 1.0, 1.0)


func _system_voice() -> String:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return ""
	var voices := DisplayServer.tts_get_voices()
	var portuguese := voices.filter(func(v): return String(v["language"]).begins_with("pt"))
	if portuguese.is_empty():
		return ""
	for name in PREFERRED:
		for v in portuguese:
			if String(v["name"]).contains(name):
				return v["id"]
	return portuguese[0]["id"]
