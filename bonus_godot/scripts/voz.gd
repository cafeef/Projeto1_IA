class_name Voz
extends Node
## Leitura em voz alta: Voz.say(["instrucoes"]), Voz.text("instrucoes").
##
## Prioridade: gravações em res://audio/voz/<id>.ogg|.mp3|.wav (voz humana ou
## neural, ver audio/README.md). Se faltar alguma gravação da frase pedida,
## usa a voz do sistema (texto para fala), que em alguns computadores soa
## robótica. Os textos ficam em res://audio/frases.json.
##
## É uma classe comum com funções estáticas (não um autoload): funciona sem
## nenhum registro no project.godot. O nó que toca o áudio é criado na
## primeira fala e pendurado na raiz da árvore de cenas.

const DIR := "res://audio/voz/"
const PHRASES := "res://audio/frases.json"
const EXTENSIONS := ["ogg", "mp3", "wav"]
## Vozes de sistema mais naturais, na ordem de preferência.
const PREFERRED := ["Francisca", "Thalita", "Maria", "Luciana", "Google", "Microsoft", "Daniel"]

static var _frases := {}
static var _instance: Voz

var _player: AudioStreamPlayer
var _queue: Array = []


func _init() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_play_next)


static func text(id: String) -> String:
	if _frases.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PHRASES))
		if typeof(data) == TYPE_DICTIONARY:
			_frases = data
	return _frases.get(id, id)


static func has_clip(id: String) -> bool:
	return _clip_path(id) != ""


## Fala uma sequência de frases (ids de frases.json). Textos que não são ids
## (fases criadas no editor) vão direto para a voz do sistema.
## system_fallback=false: sem gravação, fica em silêncio (usado nas falas
## automáticas, para não tocar a voz robótica sem a criança pedir).
static func say(ids: Array, system_fallback := true) -> void:
	stop()
	if ids.all(func(id): return has_clip(id)):
		var voz := _node()
		voz._queue = ids.duplicate()
		voz._play_next()
	elif system_fallback:
		var parts := PackedStringArray()
		for id in ids:
			parts.append(text(id))
		_system_say(" ".join(parts))


static func stop() -> void:
	if _instance != null and is_instance_valid(_instance):
		_instance._queue.clear()
		_instance._player.stop()
	if _system_voice() != "":
		DisplayServer.tts_stop()


## True enquanto uma gravação está tocando (usado nos testes).
static func is_playing() -> bool:
	return _instance != null and is_instance_valid(_instance) and _instance._player.playing


static func _node() -> Voz:
	if _instance == null or not is_instance_valid(_instance):
		_instance = Voz.new()
		_instance.name = "Voz"
		(Engine.get_main_loop() as SceneTree).root.add_child(_instance)
	return _instance


func _play_next() -> void:
	if _queue.is_empty():
		return
	var stream = load(_clip_path(_queue.pop_front()))
	if stream is AudioStream:
		_player.stream = stream
		_player.play()
	else:
		_play_next()


static func _clip_path(id: String) -> String:
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [DIR, id, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


static func _system_say(message: String) -> void:
	var voice := _system_voice()
	if voice != "":
		DisplayServer.tts_speak(message, voice, 80, 1.0, 1.0)


static func _system_voice() -> String:
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
