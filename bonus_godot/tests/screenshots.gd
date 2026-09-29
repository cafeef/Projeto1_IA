extends SceneTree
## Percorre as telas do jogo e salva capturas (para conferência visual).
## Uso: xvfb-run godot --path bonus_godot --script res://tests/screenshots.gd -- <pasta>

var main: Control
var out := "user://capturas"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _moves(game: GameScreen, moves: Array) -> void:
	for m in moves:
		game._try_move(m)
		await _wait(0.12)


func _run() -> void:
	Progress.teacher_mode = false
	Progress.stars = {"01_simple.json": 3, "02_intermediate.json": 2}
	await _wait(0.6)
	await _shot("01_inicio")
	main.show_help()
	await _wait(0.3)
	await _shot("02_como_jogar")
	main.show_levels()
	await _wait(0.3)
	await _shot("03_fases")

	Progress.teacher_mode = true  # libera a fase 5 para a captura
	main.play_level(4)
	await _wait(0.5)
	await _shot("04_instrucao")
	var game: GameScreen = main.current
	game._begin_mission()
	var up := Vector2i(0, -1)
	var down := Vector2i(0, 1)
	var right := Vector2i(1, 0)
	await _moves(game, [down, down, right, right, right, right, right, right])
	await _wait(1.0)
	await _shot("05_jogando")
	var rest := []
	for i in 11:
		rest.append(right)
	rest.append_array([up, up])
	await _moves(game, rest)
	await _wait(12.0)  # o robô joga depois da criança
	await _shot("06_resultado")

	main.play_level(5)
	await _wait(0.3)
	game = main.current
	game._begin_mission()
	await _moves(game, [right, right, right])
	game._give_up()
	await _wait(3.5)
	await _shot("07_sem_rota")

	Progress.teacher_mode = false  # como a criança vê
	main.play_level(1)
	await _wait(0.3)
	game = main.current
	game._begin_mission()
	await _moves(game, [right, right, right, down, down, right])
	await _wait(1.5)
	await _shot("09_crianca")

	main.show_editor(null)
	await _wait(0.3)
	main.current._generate()
	await _wait(0.3)
	await _shot("08_editor")
	quit()
