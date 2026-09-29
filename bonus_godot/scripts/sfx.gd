class_name Sfx
extends Node
## Efeitos sonoros sintetizados na hora (sem arquivos de áudio).

const RATE := 22050
var _players := {}


func _ready() -> void:
	_add("step", [[660, 0.05]], 0.25)
	_add("bump", [[140, 0.12]], 0.5)
	_add("robot", [[880, 0.04], [1175, 0.04]], 0.18)
	_add("win", [[523, 0.12], [659, 0.12], [784, 0.12], [1047, 0.3]], 0.35)
	_add("fail", [[392, 0.18], [330, 0.18], [262, 0.35]], 0.35)
	_add("click", [[990, 0.03]], 0.2)


func play(sound: String) -> void:
	if _players.has(sound):
		_players[sound].play()


## notes: lista de [frequência Hz, duração s]; envelope curto evita estalos.
func _add(sound: String, notes: Array, volume: float) -> void:
	var data := PackedByteArray()
	for note in notes:
		var samples := int(RATE * note[1])
		for i in samples:
			var env := minf(1.0, minf(i / 200.0, (samples - i) / 400.0))
			var v := sin(TAU * note[0] * i / RATE) * env * volume
			var sample := int(clampf(v, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xFF)
			data.append((sample >> 8) & 0xFF)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	_players[sound] = player
