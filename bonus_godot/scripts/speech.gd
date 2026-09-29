class_name Speech
extends RefCounted
## Leitura em voz alta (texto para fala do sistema), para quem ainda não lê
## com facilidade. Se o sistema não tiver voz em português, não faz nada.


static func available() -> bool:
	return not _voice().is_empty()


static func say(text: String) -> void:
	var voice := _voice()
	if voice.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice, 70, 1.0, 0.9)


static func _voice() -> String:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return ""
	var voices := DisplayServer.tts_get_voices_for_language("pt")
	return voices[0] if voices.size() > 0 else ""
