extends Control
## Navegação entre as telas: início, como jogar, fases, jogo e editor.

## Mesmos mapas do projeto principal (scenarios/), na ordem das fases.
const LEVELS := [
	"01_simple.json", "02_intermediate.json", "03_advanced.json",
	"04_expert.json", "05_cost_tradeoff.json", "06_impossible.json",
]

var sfx: Sfx
var current: Control
var algorithm := "A*"


func _ready() -> void:
	Progress.load_data()
	theme = UI.make_theme()
	AudioServer.set_bus_mute(0, not Progress.sound_on)
	sfx = Sfx.new()
	add_child(sfx)
	show_title()


func _swap(node: Control) -> void:
	if current:
		current.queue_free()
	current = node
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)


func _page(title: String, on_back: Callable) -> VBoxContainer:
	var page := Control.new()
	_swap(page)
	UI.background(page)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	page.add_child(margin)
	var v := UI.vbox(18)
	margin.add_child(v)
	var top := UI.hbox(16)
	v.add_child(top)
	top.add_child(UI.button("Voltar", UI.GRAY, on_back, Vector2(150, 64)))
	var t := UI.label(title, 40, UI.INK)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(t)
	return v


# ---------------------------------------------------------------- início


func show_title() -> void:
	var page := Control.new()
	_swap(page)
	UI.background(page, Color("bde6ff"), Color("eafbe4"))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var v := UI.vbox(16)
	center.add_child(v)
	var hero := func(ci, s, t):
		var u: float = s.y
		Art.draw_player(ci, Vector2(s.x / 2 - u * 1.3, s.y * 0.55), u * 0.9, t)
		Art.draw_robot(ci, Vector2(s.x / 2 - u * 0.3, s.y * 0.55), u * 0.8, t)
		Art.draw_focus(ci, Vector2(s.x / 2 + u * 0.9, s.y * 0.6), u * 0.8, "Pneu")
		Art.draw_mosquito(ci, Vector2(s.x / 2 + u * 0.9, s.y * 0.35), u, t)
	v.add_child(UI.Doodle.new(hero, Vector2(600, 150), true))
	v.add_child(UI.label("Missão Dengue", 72, UI.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label("Encontre os criadouros do mosquito com o Robô Ajudante!", 28, UI.INK, HORIZONTAL_ALIGNMENT_CENTER))
	var play := UI.button("Jogar", UI.GREEN, show_levels, Vector2(420, 96), 44)
	var play_center := CenterContainer.new()
	play_center.add_child(play)
	v.add_child(play_center)
	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("Como jogar", UI.BLUE, show_help, Vector2(230, 72)))
	row.add_child(UI.button("Criar fase", UI.ORANGE, show_editor.bind(null), Vector2(230, 72)))
	var teacher := UI.button(_teacher_text(), UI.PURPLE, func() -> void: pass, Vector2(300, 72), 24)
	var toggle_teacher := func() -> void:
		Progress.teacher_mode = not Progress.teacher_mode
		Progress.save_data()
		teacher.text = _teacher_text()
	teacher.pressed.connect(toggle_teacher)
	row.add_child(teacher)
	var sound := UI.button(_sound_text(), UI.GRAY, func() -> void: pass, Vector2(180, 72), 24)
	var toggle_sound := func() -> void:
		Progress.sound_on = not Progress.sound_on
		AudioServer.set_bus_mute(0, not Progress.sound_on)
		Progress.save_data()
		sound.text = _sound_text()
	sound.pressed.connect(toggle_sound)
	row.add_child(sound)
	play.grab_focus.call_deferred()


func _teacher_text() -> String:
	return "Modo professor: " + ("ligado" if Progress.teacher_mode else "desligado")


func _sound_text() -> String:
	return "Som: " + ("ligado" if Progress.sound_on else "desligado")


func show_help() -> void:
	var v := _page("Como jogar", show_title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	var terrains := func(ci, s, _t):
		var w: float = minf(s.y * 0.8, s.x / 3.2)
		var kinds := [GridProblem.Cell.FREE, GridProblem.Cell.GRASS, GridProblem.Cell.DIFFICULT]
		for i in 3:
			Art.draw_tile(ci, Rect2(Vector2(s.x / 2 - w * 1.5 + i * w, s.y * 0.1), Vector2(w, w)), kinds[i], i)
	var focus_art := func(ci, s, t):
		Art.draw_focus(ci, s / 2, s.y, "Vaso")
		Art.draw_mosquito(ci, s / 2 - Vector2(0, s.y * 0.25), s.y, t)
	var steps := [
		[func(ci, s, t): Art.draw_player(ci, s / 2, s.y, t), "1. Você é a criança de camiseta laranja. Ande com as setas do teclado, com os botões laranja ou tocando na casa ao lado."],
		[terrains, "2. Calçada gasta 1 de energia, grama gasta 2 e lama gasta 4. Muros não deixam passar. Tente gastar pouca energia!"],
		[func(ci, s, t): Art.draw_robot(ci, s / 2, s.y, t), "3. O Robô Ajudante procura o mesmo foco. As casas azuis são os lugares que ele olhou antes de decidir o caminho."],
		[focus_art, "4. Chegue no foco para eliminar o criadouro do mosquito e aprender como evitar a dengue."],
	]
	var all_text := ""
	for step in steps:
		var c := UI.card()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(c)
		var h := UI.hbox(16)
		c.add_child(h)
		h.add_child(UI.Doodle.new(step[0], Vector2(150, 110), true))
		var l := UI.label(step[1], 25, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
		all_text += step[1] + " "
	var listen := UI.button("Ouvir as instruções", UI.BLUE, func() -> void: Speech.say(all_text), Vector2(0, 72))
	v.add_child(listen)
	listen.grab_focus.call_deferred()


# ------------------------------------------------------------------ fases


func _unlocked(index: int) -> bool:
	return Progress.teacher_mode or index == 0 or Progress.stars_for(LEVELS[index - 1]) > 0


func show_levels() -> void:
	var v := _page("Escolha a fase", show_title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	v.add_child(grid)
	var first: Button
	for i in LEVELS.size():
		var problem := GridProblem.from_file("res://levels/" + LEVELS[i])
		var open := _unlocked(i)
		var stars := Progress.stars_for(LEVELS[i])
		var card := UI.button("", UI.CARD if open else Color("e3e8ee"), play_level.bind(i), Vector2(390, 210))
		card.disabled = not open
		for state in ["disabled"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("e3e8ee")
			box.set_corner_radius_all(18)
			card.add_theme_stylebox_override(state, box)
		grid.add_child(card)
		var focus := problem.focus
		var art := func(ci, s, t):
			if open:
				Art.draw_focus(ci, Vector2(70, 95), 110, focus)
				Art.draw_mosquito(ci, Vector2(70, 60), 110, t)
			else:
				UI.draw_lock(ci, Vector2(70, 100), 40)
			for k in 3:
				UI.draw_star(ci, Vector2(170 + k * 50, 170), 20, k < stars)
		card.add_child(UI.Doodle.new(art, Vector2(390, 210), true))
		var name := UI.label("Fase %d\n%s" % [i + 1, problem.name], 24, UI.INK if open else UI.GRAY, HORIZONTAL_ALIGNMENT_LEFT, true)
		name.position = Vector2(140, 20)
		name.size = Vector2(240, 120)
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name)
		if open and first == null:
			first = card
	var custom := Progress.list_custom()
	if not custom.is_empty():
		v.add_child(UI.label("Minhas fases", 30))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 12)
		row.add_theme_constant_override("v_separation", 12)
		v.add_child(row)
		for path in custom:
			var p := GridProblem.from_file(path)
			row.add_child(UI.button(p.name, UI.ORANGE, play_custom.bind(path), Vector2(220, 64), 22))
	if first:
		first.grab_focus.call_deferred()


func play_level(index: int) -> void:
	var problem := GridProblem.from_file("res://levels/" + LEVELS[index])
	var title := "Fase %d – %s" % [index + 1, problem.name]
	var has_next := index + 1 < LEVELS.size()
	_play(problem, LEVELS[index], title, has_next, play_level.bind(index), show_levels, play_level.bind(index + 1))


func play_custom(path: String) -> void:
	var problem := GridProblem.from_file(path)
	_play(problem, path, problem.name, false, play_custom.bind(path), show_levels, Callable())


func _play(problem: GridProblem, id: String, title: String, has_next: bool, replay: Callable, exit: Callable, next: Callable) -> void:
	var game := GameScreen.new()
	_swap(game)
	game.start(problem, id, title, has_next, sfx, algorithm)
	game.exit_requested.connect(exit)
	var on_replay := func() -> void:
		algorithm = game.algorithm
		replay.call()
	game.replay_requested.connect(on_replay)
	if next.is_valid():
		game.next_requested.connect(next)


# ----------------------------------------------------------------- editor


func show_editor(problem: GridProblem = null) -> void:
	var editor := EditorScreen.new()
	_swap(editor)
	editor.start(problem, sfx)
	editor.exit_requested.connect(show_title)
	editor.test_requested.connect(func(p: GridProblem) -> void:
		_play(p, "", "Testando: " + p.name, false, func() -> void: show_editor(p), show_editor.bind(p), Callable()))
	editor.saved.connect(func(_path: String) -> void: pass)
