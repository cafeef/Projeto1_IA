class_name Board
extends Control
## Desenha a grade, o jogador, o robô, o foco e as animações. Não decide
## regras: quem move e valida é a tela do jogo (GridProblem).

signal cell_pressed(cell: Vector2i)
signal cell_dragged(cell: Vector2i)

var problem: GridProblem
var player_cell := Vector2i.ZERO
var player_trail: Array = []
var robot_result := {}
var robot_explored := 0  # quantos estados expandidos já foram mostrados
var robot_step := -1  # índice no caminho; -1 = ainda pensando
var show_player := true
var show_robot := true
var focus_cleared := false
var editor_mode := false
var hover := Vector2i(-1, -1)

var _t := 0.0
var _player_draw := Vector2.ZERO
var _robot_draw := Vector2.ZERO
var _shake := 0.0
var _confetti: Array = []
var _dragging := false


func setup(p: GridProblem) -> void:
	problem = p
	player_cell = p.start
	player_trail = [p.start]
	robot_result = {}
	robot_explored = 0
	robot_step = -1
	focus_cleared = false
	_player_draw = Vector2(p.start)
	_robot_draw = Vector2(p.start)
	_confetti.clear()
	queue_redraw()


func tile_size() -> float:
	if problem == null:
		return 0.0
	return floorf(minf(size.x / problem.cols, size.y / problem.rows))


func origin() -> Vector2:
	var s := tile_size()
	return ((size - Vector2(problem.cols, problem.rows) * s) / 2.0).floor()


func cell_rect(c: Vector2i) -> Rect2:
	var s := tile_size()
	return Rect2(origin() + Vector2(c) * s, Vector2(s, s))


func cell_at(point: Vector2) -> Vector2i:
	var s := tile_size()
	var local := (point - origin()) / s
	return Vector2i(floori(local.x), floori(local.y))


func bump() -> void:
	_shake = 0.25


func celebrate() -> void:
	var c := cell_rect(problem.goal).get_center()
	for i in 60:
		var angle := randf() * TAU
		_confetti.append({
			"p": c, "v": Vector2(cos(angle), sin(angle)) * randf_range(120, 380) + Vector2(0, -200),
			"color": Color.from_hsv(randf(), 0.7, 1.0), "life": randf_range(0.8, 1.6),
		})


func robot_cell() -> Vector2i:
	if robot_step >= 0 and robot_result.get("found", false):
		return robot_result["path"][robot_step]
	return problem.start


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta)
	_player_draw = _player_draw.lerp(Vector2(player_cell), minf(1.0, delta * 14.0))
	_robot_draw = _robot_draw.lerp(Vector2(robot_cell()), minf(1.0, delta * 10.0))
	for piece in _confetti:
		piece["v"] += Vector2(0, 600) * delta
		piece["p"] += piece["v"] * delta
		piece["life"] -= delta
	_confetti = _confetti.filter(func(piece): return piece["life"] > 0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if problem == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			var c := cell_at(event.position)
			if problem.inside(c):
				cell_pressed.emit(c)
	elif event is InputEventMouseMotion:
		var c := cell_at(event.position)
		hover = c if problem.inside(c) else Vector2i(-1, -1)
		if _dragging and editor_mode and problem.inside(c):
			cell_dragged.emit(c)
	elif event is InputEventScreenTouch and event.pressed:
		var c := cell_at(event.position)
		if problem.inside(c):
			cell_pressed.emit(c)


func _draw() -> void:
	if problem == null:
		return
	var s := tile_size()
	if _shake > 0:
		draw_set_transform(Vector2(sin(_t * 90.0) * 6.0 * _shake / 0.25, 0), 0, Vector2.ONE)
	for r in problem.rows:
		for c in problem.cols:
			Art.draw_tile(self, cell_rect(Vector2i(c, r)), problem.cells[r][c], r * 131 + c)

	# Estados que o robô "olhou" e caminho que ele escolheu.
	if not robot_result.is_empty():
		var explored: Array = robot_result["explored"]
		for i in mini(robot_explored, explored.size()):
			draw_rect(cell_rect(explored[i]).grow(-s * 0.06), Art.EXPLORED)
		if robot_step >= 0:
			var path: Array = robot_result["path"]
			for i in range(1, path.size()):
				draw_line(cell_rect(path[i - 1]).get_center(), cell_rect(path[i]).get_center(), Art.ROBOT_PATH, s * 0.12, true)

	# Pegadas do jogador.
	for i in range(1, player_trail.size()):
		var a := cell_rect(player_trail[i - 1]).get_center()
		var b := cell_rect(player_trail[i]).get_center()
		draw_circle(a.lerp(b, 0.35), s * 0.07, Art.TRAIL)
		draw_circle(a.lerp(b, 0.7), s * 0.07, Art.TRAIL)

	Art.draw_start(self, cell_rect(problem.start).grow(-s * 0.1))
	var goal_rect := cell_rect(problem.goal)
	Art.draw_focus(self, goal_rect.get_center(), s, problem.focus, not focus_cleared)
	if not focus_cleared:
		Art.draw_mosquito(self, goal_rect.get_center() + Vector2(0, -s * 0.2), s, _t)
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	draw_rect(goal_rect.grow(-2), Color(1, 0.2, 0.2, 0.35 + 0.4 * pulse), false, maxf(2.0, s * 0.06))

	if editor_mode and problem.inside(hover):
		draw_rect(cell_rect(hover), Color(1, 1, 1, 0.6), false, 3.0)

	var o := origin()
	if show_robot and not robot_result.is_empty():
		Art.draw_robot(self, o + (_robot_draw + Vector2(0.5, 0.5)) * s + Vector2(s * 0.12, 0), s * 0.8, _t)
	if show_player:
		Art.draw_player(self, o + (_player_draw + Vector2(0.5, 0.5)) * s - Vector2(s * 0.1, 0), s * 0.85, _t)

	for piece in _confetti:
		draw_rect(Rect2(piece["p"], Vector2(8, 8)), piece["color"])
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
