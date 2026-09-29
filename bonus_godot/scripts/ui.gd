class_name UI
extends RefCounted
## Tema e componentes de interface: letras grandes, botões grandes e cores
## contrastantes, pensando em crianças e em pessoas com deficiência intelectual.

const BG := Color("dff3ff")
const INK := Color("1d2b3a")
const GREEN := Color("2e9e5b")
const BLUE := Color("3a86ff")
const ORANGE := Color("f48c06")
const PURPLE := Color("8e5cd9")
const RED := Color("e63946")
const GRAY := Color("8d99ae")
const CARD := Color("ffffff")


## Control que só desenha: recebe uma função (canvas, tamanho, tempo).
class Doodle:
	extends Control
	var painter: Callable
	var animated := false
	var _t := 0.0

	func _init(p: Callable, min_size := Vector2(64, 64), anim := false) -> void:
		painter = p
		custom_minimum_size = min_size
		animated = anim
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if animated:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		painter.call(self, size, _t)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 26
	theme.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": BLUE, "hover": BLUE.lightened(0.15), "pressed": BLUE.darkened(0.2),
			"disabled": GRAY, "focus": BLUE}[state]
		box.set_corner_radius_all(18)
		box.set_content_margin_all(14)
		if state == "focus":
			box.draw_center = false
			box.border_color = Color("ffd166")
			box.set_border_width_all(5)
		theme.set_stylebox(state, "Button", box)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.7))
	var panel := StyleBoxFlat.new()
	panel.bg_color = CARD
	panel.set_corner_radius_all(24)
	panel.set_content_margin_all(18)
	panel.shadow_color = Color(0, 0, 0, 0.15)
	panel.shadow_size = 8
	theme.set_stylebox("panel", "PanelContainer", panel)
	return theme


static func button(text: String, color: Color, on_press: Callable, min_size := Vector2(0, 72), font_size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color if state == "normal" else (color.lightened(0.15) if state == "hover" else color.darkened(0.2))
		box.set_corner_radius_all(18)
		box.set_content_margin_all(12)
		box.shadow_color = Color(0, 0, 0, 0.2)
		box.shadow_size = 3 if state != "pressed" else 0
		b.add_theme_stylebox_override(state, box)
	b.pressed.connect(on_press)
	return b


## Botão com desenho no lugar do texto (setas, alto-falante...).
static func icon_button(painter: Callable, color: Color, on_press: Callable, min_size := Vector2(88, 88)) -> Button:
	var b := button("", color, on_press, min_size)
	var d := Doodle.new(painter, Vector2.ZERO)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(d)
	return b


## wrap=true quebra linhas; só use onde o contêiner dá largura ao texto
## (VBox, cartões), senão o rótulo encolhe até uma letra por linha.
static func label(text: String, font_size := 26, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func card(color := CARD, margin := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(24)
	box.set_content_margin_all(margin)
	box.shadow_color = Color(0, 0, 0, 0.15)
	box.shadow_size = 8
	p.add_theme_stylebox_override("panel", box)
	return p


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## Fundo de tela inteira com um leve degradê.
static func background(parent: Control, top := BG, bottom := Color("f7fbff")) -> void:
	var painter := func(ci: CanvasItem, s: Vector2, _t: float) -> void:
		var steps := 24
		for i in steps:
			var y0 := s.y * i / steps
			ci.draw_rect(Rect2(0, y0, s.x, s.y / steps + 1), top.lerp(bottom, float(i) / steps))
	var bg := Doodle.new(painter, Vector2.ZERO)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)


## Camada escura que cobre a tela, com um cartão centralizado.
static func overlay(parent: Control, width := 760) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.name = "Overlay"
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var c := card()
	c.custom_minimum_size = Vector2(width, 0)
	center.add_child(c)
	var v := vbox(14)
	c.add_child(v)
	return v


## Nó da camada escura que contém o cartão devolvido por overlay().
static func overlay_root(content: Control) -> Control:
	return content.get_parent().get_parent().get_parent()


# ------------------------------------------------------------ desenhos


static func draw_arrow(ci: CanvasItem, s: Vector2, direction: Vector2i) -> void:
	var c := s / 2.0
	var r := minf(s.x, s.y) * 0.3
	var angle := Vector2(direction).angle()
	var pts := PackedVector2Array()
	for p in [Vector2(1, 0), Vector2(-0.6, -0.8), Vector2(-0.6, 0.8)]:
		pts.append(c + p.rotated(angle) * r)
	ci.draw_colored_polygon(pts, Color.WHITE)


static func draw_star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	ci.draw_colored_polygon(pts, Color("ffc300") if filled else Color("d6dde6"))
	pts.append(pts[0])
	ci.draw_polyline(pts, Color("b8860b") if filled else Color("aab4c0"), 2.0, true)


static func draw_speaker(ci: CanvasItem, s: Vector2) -> void:
	var c := s / 2.0
	var u := minf(s.x, s.y) * 0.1
	ci.draw_rect(Rect2(c + Vector2(-3.2, -1.2) * u, Vector2(1.6, 2.4) * u), Color.WHITE)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.6, -1.2) * u, c + Vector2(0.4, -3) * u,
		c + Vector2(0.4, 3) * u, c + Vector2(-1.6, 1.2) * u]), Color.WHITE)
	ci.draw_arc(c + Vector2(0.6, 0) * u, 1.6 * u, -0.9, 0.9, 12, Color.WHITE, 0.5 * u)
	ci.draw_arc(c + Vector2(0.6, 0) * u, 2.8 * u, -0.9, 0.9, 12, Color.WHITE, 0.5 * u)


static func draw_lock(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_arc(c + Vector2(0, -r * 0.3), r * 0.5, PI, TAU, 16, Color("6c757d"), r * 0.2)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.3), Vector2(r * 1.5, r * 1.1)), Color("6c757d"))
	ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.18, Color.WHITE)
