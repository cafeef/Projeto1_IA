class_name EditorScreen
extends Control
## Editor de fases: pintar terrenos, mover casa e foco, gerar um mapa
## automaticamente, testar e salvar. O robô (A*) avisa se há caminho.

signal exit_requested
signal test_requested(problem: GridProblem)
signal saved(path: String)

const TOOLS := [
	["Calçada", GridProblem.Cell.FREE],
	["Grama", GridProblem.Cell.GRASS],
	["Lama", GridProblem.Cell.DIFFICULT],
	["Muro", GridProblem.Cell.OBSTACLE],
	["Casa", "start"],
	["Foco", "goal"],
]
const SIZES := [["Pequena", Vector2i(8, 8)], ["Média", Vector2i(12, 9)], ["Grande", Vector2i(16, 11)]]

var problem: GridProblem
var sfx: Sfx
var tool: Variant = GridProblem.Cell.OBSTACLE
var board: Board
var _status: Label
var _focus_label: Label
var _tool_buttons := []


func start(p: GridProblem, sounds: Sfx) -> void:
	sfx = sounds
	problem = p if p != null else _blank(Vector2i(12, 9))
	_build()
	board.setup(problem)
	board.editor_mode = true
	board.show_player = false
	board.show_robot = false
	_select_tool(3)
	_refresh()


func _blank(dims: Vector2i) -> GridProblem:
	var lines := []
	for r in dims.y:
		var line := ""
		for c in dims.x:
			var border := r == 0 or c == 0 or r == dims.y - 1 or c == dims.x - 1
			line += "#" if border else "."
		lines.append(line)
	var focus: Dictionary = Art.FOCUS_TYPES[0]
	var p := GridProblem.from_dict({"name": "Minha fase", "focus": focus["name"], "message": focus["message"], "grid": lines})
	p.start = Vector2i(1, 1)
	p.goal = dims - Vector2i(2, 2)
	return p


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UI.background(self, Color("fff4e0"), Color("fffdf7"))
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
	var title := UI.label("Criar fase", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	for item in SIZES:
		top.add_child(UI.button(item[0], UI.BLUE, _resize.bind(item[1]), Vector2(130, 60), 22))

	var main := UI.hbox(16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)
	board = Board.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.cell_pressed.connect(_paint)
	board.cell_dragged.connect(_paint)
	main.add_child(board)

	var side := UI.vbox(10)
	side.custom_minimum_size = Vector2(380, 0)
	main.add_child(side)
	side.add_child(UI.label("1. Escolha e pinte:", 22))
	var tools := GridContainer.new()
	tools.columns = 2
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	side.add_child(tools)
	for i in TOOLS.size():
		var b := UI.button("      " + TOOLS[i][0], UI.BLUE, _select_tool.bind(i), Vector2(182, 58), 22)
		var kind = TOOLS[i][1]
		var art := func(ci, s, t):
			var r := Rect2(Vector2(8, (s.y - 40) / 2), Vector2(40, 40))
			if kind is String:
				Art.draw_tile(ci, r, GridProblem.Cell.FREE, 1)
				if kind == "start":
					Art.draw_start(ci, r)
				else:
					Art.draw_focus(ci, r.get_center(), 40, Art.FOCUS_TYPES[0]["name"])
			else:
				Art.draw_tile(ci, r, kind, 1)
		var d := UI.Doodle.new(art, Vector2.ZERO)
		d.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(d)
		tools.add_child(b)
		_tool_buttons.append(b)

	side.add_child(UI.label("2. Tipo de foco:", 22))
	var focus_row := UI.hbox(8)
	side.add_child(focus_row)
	focus_row.add_child(UI.icon_button(func(ci, s, _t): UI.draw_arrow(ci, s, Vector2i(-1, 0)), UI.ORANGE, _cycle_focus.bind(-1), Vector2(56, 56)))
	_focus_label = UI.label("", 20, UI.RED, HORIZONTAL_ALIGNMENT_CENTER)
	_focus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_row.add_child(_focus_label)
	focus_row.add_child(UI.icon_button(func(ci, s, _t): UI.draw_arrow(ci, s, Vector2i(1, 0)), UI.ORANGE, _cycle_focus.bind(1), Vector2(56, 56)))

	side.add_child(UI.label("3. Pronto?", 22))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	side.add_child(actions)
	actions.add_child(UI.button("Gerar sozinho", UI.PURPLE, _generate, Vector2(182, 58), 22))
	actions.add_child(UI.button("Limpar", UI.GRAY, func() -> void: _resize(Vector2i(problem.cols, problem.rows)), Vector2(182, 58), 22))
	actions.add_child(UI.button("Testar", UI.GREEN, func() -> void: test_requested.emit(problem), Vector2(182, 58), 22))
	actions.add_child(UI.button("Salvar", UI.ORANGE, _save, Vector2(182, 58), 22))
	_status = UI.label("", 21, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	side.add_child(_status)


func _select_tool(index: int) -> void:
	tool = TOOLS[index][1]
	for i in _tool_buttons.size():
		_tool_buttons[i].modulate = Color.WHITE if i == index else Color(1, 1, 1, 0.55)
	if sfx:
		sfx.play("click")


func _paint(cell: Vector2i) -> void:
	if tool is String:
		if cell == problem.start or cell == problem.goal:
			return
		problem.cells[cell.y][cell.x] = GridProblem.Cell.FREE
		if tool == "start":
			problem.start = cell
		else:
			problem.goal = cell
	else:
		if cell == problem.start or cell == problem.goal:
			return  # casa e foco ficam sempre em chão livre
		if problem.cells[cell.y][cell.x] == tool:
			return
		problem.cells[cell.y][cell.x] = tool
	_refresh()


func _resize(dims: Vector2i) -> void:
	var fresh := _blank(dims)
	fresh.focus = problem.focus
	fresh.message = problem.message
	_replace(fresh)


func _replace(fresh: GridProblem) -> void:
	problem = fresh
	board.setup(problem)
	_refresh()


func _cycle_focus(step: int) -> void:
	var index := 0
	for i in Art.FOCUS_TYPES.size():
		if Art.FOCUS_TYPES[i]["name"] == problem.focus:
			index = i
	var item: Dictionary = Art.FOCUS_TYPES[posmod(index + step, Art.FOCUS_TYPES.size())]
	problem.focus = item["name"]
	problem.message = item["message"]
	_refresh()


## Mapa aleatório com borda de muros; aceita só se o robô achar um caminho
## razoavelmente longo, para a fase ter graça.
func _generate() -> void:
	var dims := Vector2i(problem.cols, problem.rows)
	for attempt in 300:
		var p := _blank(dims)
		p.focus = problem.focus
		p.message = problem.message
		for r in range(1, dims.y - 1):
			for c in range(1, dims.x - 1):
				var roll := randf()
				if roll < 0.28:
					p.cells[r][c] = GridProblem.Cell.OBSTACLE
				elif roll < 0.42:
					p.cells[r][c] = GridProblem.Cell.GRASS
				elif roll < 0.52:
					p.cells[r][c] = GridProblem.Cell.DIFFICULT
		p.start = Vector2i(1, 1)
		p.goal = Vector2i(randi_range(dims.x / 2, dims.x - 2), randi_range(dims.y / 2, dims.y - 2))
		p.cells[p.start.y][p.start.x] = GridProblem.Cell.FREE
		p.cells[p.goal.y][p.goal.x] = GridProblem.Cell.FREE
		var result := Search.bfs(p)
		if result["found"] and result["steps"] >= (dims.x + dims.y) / 2:
			_replace(p)
			if sfx:
				sfx.play("robot")
			return


func _save() -> void:
	if problem.name == "Minha fase":
		problem.name = "Minha fase %d" % (Progress.list_custom().size() + 1)
	var path := Progress.save_custom(problem)
	if sfx:
		sfx.play("win")
	_status.text = "Fase salva! Ela aparece em Jogar > Minhas fases."
	saved.emit(path)


func _refresh() -> void:
	_focus_label.text = problem.focus
	var result := Search.astar(problem)
	if result["found"]:
		_status.text = "O robô consegue chegar: %d passos, energia %d." % [result["steps"], result["cost"]]
	else:
		_status.text = "Não há caminho até o foco: vira um desafio sem rota!"
