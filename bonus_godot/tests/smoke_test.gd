extends SceneTree
## Teste de fumaça sem janela: abre uma fase, aperta teclas de verdade (com um
## botão da tela em foco) e confere movimento, custo, obstáculo e chegada.
## Uso: godot --headless --path bonus_godot --script res://tests/smoke_test.gd

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FALHA ") + what)
	if not ok:
		failures += 1


func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _run() -> void:
	Progress.teacher_mode = false
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.play_level(0)  # Quintal simples: S em (1,1), F em (6,5)
	await process_frame
	var game: GameScreen = main.current
	_check(not game.mission_started, "missão espera o 'Vamos lá!'")
	game._begin_mission()
	await process_frame
	_find_button(game).grab_focus()  # simula clique numa seta da tela
	await _key(KEY_UP)
	_check(game.board.player_cell == Vector2i(1, 1) and game.player_steps == 0, "muro não conta passo")
	for code in [KEY_RIGHT, KEY_RIGHT, KEY_RIGHT]:
		await _key(code)
	_check(game.board.player_cell == Vector2i(4, 1), "setas movem mesmo com botão em foco")
	_check(game.player_cost == 1 + 1 + 2, "custo usa o terreno de destino (grama = 2)")
	_check(game.robot.is_empty() and game.board.robot_result.is_empty(), "robô espera a criança terminar")
	for code in [KEY_RIGHT, KEY_RIGHT, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN]:
		await _key(code)
	_check(game.player_done and game.player_steps == 9 and game.player_cost == 10, "chega ao foco com 9 passos e energia 10")
	_check(game._stars() == 3, "3 estrelas no custo ótimo")
	_check(not game.robot.is_empty() and game.robot["algorithm"] == "A*", "robô começa depois que a criança chega")
	_check(Voz.text("resultado_3").begins_with("Perfeito"), "frases carregadas de audio/frases.json")
	game._on_action()  # botão "Ver resultado" na vez do robô
	await create_timer(3.0).timeout
	var cards := game.get_children().filter(func(n): return String(n.name).begins_with("Overlay"))
	_check(game.robot_done and cards.size() == 1, "pular o robô mostra um único cartão final")
	quit(1 if failures else 0)


func _find_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.text == "":
			return child
		var found := _find_button(child)
		if found:
			return found
	return null
