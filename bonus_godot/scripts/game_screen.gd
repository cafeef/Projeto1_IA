class_name GameScreen
extends Control
## Uma missão: o jogador e o Robô Ajudante procuram o mesmo foco, no mesmo
## mapa e saindo da mesma casa. A criança joga primeiro; o robô só começa
## depois, para que ela não copie o caminho dele. Ao final, cartão educativo
## e comparação.

signal exit_requested
signal next_requested
signal replay_requested

const EXPLORE_DT := 0.06  # tempo para mostrar cada estado que o robô olhou
const WALK_DT := 0.3  # tempo para o robô andar uma casa
const KEYS := {
	KEY_UP: Vector2i(0, -1), KEY_W: Vector2i(0, -1),
	KEY_RIGHT: Vector2i(1, 0), KEY_D: Vector2i(1, 0),
	KEY_DOWN: Vector2i(0, 1), KEY_S: Vector2i(0, 1),
	KEY_LEFT: Vector2i(-1, 0), KEY_A: Vector2i(-1, 0),
}

var problem: GridProblem
var level_id := ""
var level_title := ""
var has_next := false
var sfx: Sfx
var algorithm := "A*"

var board: Board
var mission_started := false
var player_steps := 0
var player_cost := 0
var player_done := false
var gave_up := false
var robot := {}
var robot_done := false
var optimal := {}

var _clock_start := -1
var _clock_end := -1
var _robot_timer := 0.0
var _finish_timer := -1.0
var _toast_timer := 0.0
var _you_stats: Label
var _robot_status: Label
var _robot_stats: Label
var _toast: Label
var _overlay: Control


func start(p: GridProblem, id: String, title: String, next_exists: bool, sounds: Sfx, alg := "A*") -> void:
	problem = p
	level_id = id
	level_title = title
	has_next = next_exists
	sfx = sounds
	algorithm = alg if Progress.teacher_mode else "A*"
	optimal = Search.astar(problem)
	_build()
	board.setup(problem)
	_update_panels()
	_show_intro()


# --------------------------------------------------------------- layout


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UI.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root := UI.vbox(12)
	margin.add_child(root)

	var top := UI.hbox(12)
	root.add_child(top)
	top.add_child(UI.button("Voltar", UI.GRAY, func() -> void: exit_requested.emit(), Vector2(140, 60)))
	var title := UI.label(level_title, 32, UI.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS  # não empurra a tela
	top.add_child(title)
	if Progress.teacher_mode:
		top.add_child(UI.label("Robô usa:", 22))
		for name in Search.NAMES:
			var color := UI.PURPLE if name == algorithm else UI.GRAY
			top.add_child(UI.button(name, color, _choose_algorithm.bind(name), Vector2(96, 60), 22))
	top.add_child(UI.button("Não consigo chegar", UI.GRAY, _give_up, Vector2(0, 60), 20))
	top.add_child(UI.icon_button(func(ci, s, _t): UI.draw_speaker(ci, s), UI.BLUE, _speak_instructions, Vector2(72, 60)))

	var main := UI.hbox(16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)
	board = Board.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.cell_pressed.connect(_on_cell_pressed)
	main.add_child(board)

	var side := UI.vbox(8)
	side.custom_minimum_size = Vector2(360, 0)
	main.add_child(side)
	_you_stats = _person_card(side, "Você", func(ci, s, t): Art.draw_player(ci, s / 2, minf(s.x, s.y), t))
	var robot_labels: Array = _person_card(side, "Robô Ajudante", func(ci, s, t): Art.draw_robot(ci, s / 2, minf(s.x, s.y), t), true)
	_robot_status = robot_labels[0]
	_robot_stats = robot_labels[1]
	side.add_child(_legend())

	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 8)
	pad.add_theme_constant_override("v_separation", 8)
	var cells := [null, Vector2i(0, -1), null, Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]
	for d in cells:
		if d == null:
			pad.add_child(Control.new())
		else:
			var dir: Vector2i = d
			pad.add_child(UI.icon_button(func(ci, s, _t): UI.draw_arrow(ci, s, dir), UI.ORANGE, _try_move.bind(dir), Vector2(88, 54)))
	var pad_center := CenterContainer.new()
	pad_center.add_child(pad)
	side.add_child(pad_center)

	_toast = UI.label("", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true)
	var toast_box := StyleBoxFlat.new()
	toast_box.bg_color = Color(0.1, 0.15, 0.25, 0.85)
	toast_box.set_corner_radius_all(16)
	toast_box.set_content_margin_all(12)
	_toast.add_theme_stylebox_override("normal", toast_box)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(-300, 90)
	_toast.custom_minimum_size = Vector2(600, 0)
	_toast.visible = false
	add_child(_toast)


func _person_card(parent: Control, name: String, painter: Callable, with_status := false):
	var c := UI.card(UI.CARD, 10)
	parent.add_child(c)
	var h := UI.hbox(12)
	c.add_child(h)
	h.add_child(UI.Doodle.new(painter, Vector2(52, 52), true))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(name, 22, UI.INK))
	var stats := UI.label("", 19, UI.INK)
	if with_status:
		var status := UI.label("", 19, UI.PURPLE)
		v.add_child(status)
		v.add_child(stats)
		return [status, stats]
	v.add_child(stats)
	return stats


func _legend() -> PanelContainer:
	var c := UI.card(UI.CARD, 10)
	var v := UI.vbox(4)
	c.add_child(v)
	v.add_child(UI.label("Energia gasta em cada casa:", 19))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var items := [
		[GridProblem.Cell.FREE, "Calçada: 1"],
		[GridProblem.Cell.GRASS, "Grama: 2"],
		[GridProblem.Cell.DIFFICULT, "Lama: 4"],
		[GridProblem.Cell.OBSTACLE, "Muro: não passa"],
	]
	for item in items:
		var h := UI.hbox(8)
		var kind: int = item[0]
		h.add_child(UI.Doodle.new(func(ci, s, _t): Art.draw_tile(ci, Rect2(Vector2.ZERO, s), kind, 3), Vector2(30, 30)))
		h.add_child(UI.label(item[1], 19))
		grid.add_child(h)
	return c


# ---------------------------------------------------------------- jogo


func _show_intro() -> void:
	var v := UI.overlay(self, 780)
	_overlay = UI.overlay_root(v)
	var p := problem
	var focus_art := func(ci, s, t):
		Art.draw_focus(ci, s / 2, s.y * 0.9, p.focus)
		Art.draw_mosquito(ci, s / 2 + Vector2(0, -s.y * 0.2), s.y * 0.9, t)
	v.add_child(UI.Doodle.new(focus_art, Vector2(0, 150), true))
	v.add_child(UI.label(Voz.text("encontre"), 30, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(problem.focus, 36, UI.RED, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(Voz.text("instrucoes"), 24, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, true))
	var h := UI.hbox(16)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	h.add_child(UI.icon_button(func(ci, s, _t): UI.draw_speaker(ci, s), UI.BLUE, _speak_instructions, Vector2(96, 80)))
	var go := UI.button("Vamos lá!", UI.GREEN, _begin_mission, Vector2(280, 80), 34)
	h.add_child(go)
	go.grab_focus.call_deferred()


## Ids de frases.json para o foco e a mensagem; fases do editor com texto
## próprio caem no texto literal (lido pela voz do sistema).
func _focus_ids() -> Array:
	var key := Art.focus_key(problem.focus)
	var name_id := "foco_" + key
	var msg_id := "msg_" + key
	return [
		name_id if Voz.text(name_id) == problem.focus else problem.focus,
		msg_id if Voz.text(msg_id) == problem.message else problem.message,
	]


func _speak_instructions() -> void:
	Voz.say(["encontre", _focus_ids()[0], "instrucoes"])


func _begin_mission() -> void:
	sfx.play("click")
	Voz.stop()
	_close_overlay()
	mission_started = true
	_update_panels()


## Vez do robô: só depois que a criança chegou ou desistiu.
func _start_robot() -> void:
	robot = Search.run(algorithm, problem)
	board.robot_result = robot
	_robot_timer = -0.8  # pequena pausa para a criança ver o robô entrar
	_update_panels()


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null


func _choose_algorithm(name: String) -> void:
	algorithm = name
	replay_requested.emit()


## _input (e não _unhandled_input): se a criança clicou numa seta da tela,
## o botão fica com foco e as setas do teclado iriam só trocar o foco.
## Com um cartão aberto, as setas continuam navegando pelos botões dele.
func _input(event: InputEvent) -> void:
	if _overlay != null or not mission_started:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if KEYS.has(event.keycode):
			_try_move(KEYS[event.keycode])
			get_viewport().set_input_as_handled()


func _on_cell_pressed(cell: Vector2i) -> void:
	var d := cell - board.player_cell
	if absi(d.x) + absi(d.y) == 1:
		_try_move(d)


func _try_move(d: Vector2i) -> void:
	if not mission_started or player_done:
		return
	var target := board.player_cell + d
	if not problem.is_valid(target):
		board.bump()
		sfx.play("bump")
		return
	if _clock_start < 0:
		_clock_start = Time.get_ticks_msec()
	board.player_cell = target
	board.player_trail.append(target)
	player_steps += 1
	player_cost += problem.cost(target)
	sfx.play("step")
	if problem.is_goal(target):
		player_done = true
		_clock_end = Time.get_ticks_msec()
		board.focus_cleared = true
		board.celebrate()
		sfx.play("win")
		_toast_say("vez_do_robo_achou")
		_start_robot()
	_update_panels()


func _give_up() -> void:
	if not mission_started or player_done:
		return
	player_done = true
	gave_up = true
	_clock_end = Time.get_ticks_msec()
	_toast_say("vez_do_robo_desistiu")
	_start_robot()
	_update_panels()


func _process(delta: float) -> void:
	if _toast_timer > 0:
		_toast_timer -= delta
		_toast.visible = _toast_timer > 0
	if not robot.is_empty() and not robot_done:
		_robot_timer += delta
		var explored: Array = robot["explored"]
		if board.robot_explored < explored.size():
			while _robot_timer >= EXPLORE_DT and board.robot_explored < explored.size():
				_robot_timer -= EXPLORE_DT
				board.robot_explored += 1
		elif not robot["found"]:
			robot_done = true
			_update_panels()
		elif _robot_timer >= WALK_DT:
			_robot_timer = 0.0
			board.robot_step += 1
			sfx.play("robot")
			if board.robot_step >= robot["path"].size() - 1:
				robot_done = true
			_update_panels()
	if mission_started and player_done and robot_done and _finish_timer < 0:
		_finish_timer = 1.0
	if _finish_timer > 0:
		_finish_timer -= delta
		if _finish_timer <= 0:
			_show_result()


func _toast_show(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_timer = 3.0


## Aviso na tela e, se houver gravação, falado (sem a voz robótica do sistema).
func _toast_say(id: String) -> void:
	_toast_show(Voz.text(id))
	Voz.say([id], false)


func _elapsed_s() -> float:
	if _clock_start < 0:
		return 0.0
	var end := _clock_end if _clock_end >= 0 else Time.get_ticks_msec()
	return (end - _clock_start) / 1000.0


func _update_panels() -> void:
	var you := "Passos: %d\nEnergia gasta: %d" % [player_steps, player_cost]
	if Progress.teacher_mode:
		you += "\nTempo: %.1f s" % _elapsed_s()
	_you_stats.text = you
	if robot.is_empty():
		_robot_status.text = "Esperando você terminar" if mission_started else "Joga depois de você"
		_robot_stats.text = ""
		return
	if board.robot_explored < robot["explored"].size():
		_robot_status.text = "Pensando... olhou %d casas" % board.robot_explored
	elif not robot["found"]:
		_robot_status.text = "Não achou caminho!"
	elif robot_done:
		_robot_status.text = "Chegou no foco!"
	else:
		_robot_status.text = "Andando até o foco"
	var shown_steps := maxi(board.robot_step, 0)
	var shown_cost := 0
	if robot["found"]:
		for i in range(1, shown_steps + 1):
			shown_cost += problem.cost(robot["path"][i])
	var text := "Passos: %d\nEnergia gasta: %d" % [shown_steps, shown_cost]
	if Progress.teacher_mode:
		text += "\n%s: %d expandidos, %d gerados\nfronteira máx. %d, %.3f ms" % [
			robot["algorithm"], robot["expanded"], robot["generated"], robot["max_frontier"], robot["time_ms"]]
	_robot_stats.text = text


func _process_teacher_clock() -> void:
	if Progress.teacher_mode and mission_started and not player_done:
		_update_panels()


func _physics_process(_delta: float) -> void:
	_process_teacher_clock()


# ------------------------------------------------------------- resultado


func _stars() -> int:
	if not optimal["found"]:
		return 3 if gave_up else 0
	if gave_up:
		return 0
	var best: int = optimal["cost"]
	if player_cost <= best:
		return 3
	if player_cost <= ceili(best * 1.5):
		return 2
	return 1


func _show_result() -> void:
	var stars := _stars()
	if level_id != "":  # fase de teste do editor não guarda estrelas
		Progress.record(level_id, stars)
	var v := UI.overlay(self, 860)
	_overlay = UI.overlay_root(v)
	var impossible: bool = not optimal["found"]
	var title := "Foco eliminado!"
	if impossible:
		title = "Esse foco estava cercado!"
	elif gave_up:
		title = "O robô mostrou o caminho!"
	v.add_child(UI.label(title, 38, UI.GREEN, HORIZONTAL_ALIGNMENT_CENTER))

	var h := UI.hbox(18)
	v.add_child(h)
	var p := problem
	h.add_child(UI.Doodle.new(func(ci, s, _t): Art.draw_focus(ci, s / 2, s.y, p.focus, false), Vector2(130, 130)))
	var info := UI.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UI.label(problem.focus, 30, UI.RED))
	info.add_child(UI.label(problem.message, 26, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, true))

	var star_count := stars
	var star_art := func(ci, s, _t):
		for i in 3:
			UI.draw_star(ci, Vector2(s.x / 2 + (i - 1) * 70, s.y / 2), 30, i < star_count)
	v.add_child(UI.Doodle.new(star_art, Vector2(0, 70)))
	var feedback_id := _feedback(stars, impossible)
	v.add_child(UI.label(Voz.text(feedback_id), 26, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, true))
	v.add_child(UI.label(_comparison(), 22, UI.INK, HORIZONTAL_ALIGNMENT_CENTER, true))

	var buttons := UI.hbox(14)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(buttons)
	var spoken := [feedback_id] + _focus_ids()
	buttons.add_child(UI.icon_button(func(ci, s, _t): UI.draw_speaker(ci, s), UI.BLUE, func() -> void: Voz.say(spoken), Vector2(90, 76)))
	buttons.add_child(UI.button("Jogar de novo", UI.ORANGE, func() -> void: replay_requested.emit(), Vector2(0, 76)))
	buttons.add_child(UI.button("Fases", UI.GRAY, func() -> void: exit_requested.emit(), Vector2(0, 76)))
	if has_next:
		var next := UI.button("Próxima fase", UI.GREEN, func() -> void: next_requested.emit(), Vector2(0, 76))
		buttons.add_child(next)
		next.grab_focus.call_deferred()
	Voz.say(spoken, false)  # com gravações, o cartão já é lido sozinho


## Id da frase de resultado (frases.json).
func _feedback(stars: int, impossible: bool) -> String:
	if impossible:
		return "cercado_desistiu" if gave_up else "cercado"
	return "resultado_%d" % stars


func _comparison() -> String:
	var you := "Você: %d passos, energia %d" % [player_steps, player_cost]
	if gave_up:
		you = "Você: parou depois de %d passos" % player_steps
	var bot := "Robô: não achou caminho"
	if robot["found"]:
		bot = "Robô: %d passos, energia %d" % [robot["steps"], robot["cost"]]
	var text := you + "     " + bot
	if Progress.teacher_mode:
		text += "\nTempo do usuário: %.1f s · %s: %.3f ms, %d expandidos, %d gerados, fronteira máx. %d" % [
			_elapsed_s(), robot["algorithm"], robot["time_ms"], robot["expanded"], robot["generated"], robot["max_frontier"]]
		if optimal["found"]:
			text += "\nMenor energia possível (A*): %d" % optimal["cost"]
	return text
