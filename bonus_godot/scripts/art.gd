class_name Art
extends RefCounted
## Desenhos do jogo feitos com primitivas (sem arquivos de imagem):
## terrenos, personagens, focos de dengue e mosquito.

const FREE := Color("efe6d2")
const FREE_DOT := Color("d9ccb0")
const GRASS := Color("8fce6a")
const GRASS_BLADE := Color("5ea83e")
const MUD := Color("a0714a")
const MUD_PUDDLE := Color("7a5234")
const WALL := Color("5b5f6b")
const WALL_LINE := Color("444854")
const PLAYER := Color("ff9f1c")
const ROBOT := Color("8e5cd9")
const START := Color("3a86ff")
const EXPLORED := Color(0.35, 0.65, 1.0, 0.28)
const ROBOT_PATH := Color(0.56, 0.36, 0.85, 0.55)
const TRAIL := Color(1.0, 0.8, 0.2, 0.45)

## Tipos de criadouro, na ordem usada pelo editor de fases.
const FOCUS_TYPES := [
	{"key": "recipiente", "name": "Recipiente destampado", "message": "Elimine recipientes que acumulam água no quintal e mantenha-os cobertos."},
	{"key": "vaso", "name": "Vaso e prato de planta", "message": "Vasos e pratos de plantas devem ser limpos semanalmente para não acumular água."},
	{"key": "garrafa", "name": "Garrafa com água acumulada", "message": "Garrafas devem ser guardadas com a boca para baixo, em local coberto."},
	{"key": "pneu", "name": "Pneu com água acumulada", "message": "Pneus expostos acumulam água: mantenha-os cobertos ou dê a destinação adequada."},
	{"key": "caixa", "name": "Caixa-d'água mal tampada", "message": "Caixas de água devem permanecer bem tampadas para impedir a proliferação do mosquito."},
	{"key": "balde", "name": "Balde com água parada", "message": "Baldes sem uso devem ficar de boca para baixo, cobertos ou ser descartados corretamente."},
]


static func focus_key(focus_name: String) -> String:
	var lower := focus_name.to_lower()
	for item in FOCUS_TYPES:
		if lower.contains(item["key"]):
			return item["key"]
	return "recipiente"


static func draw_tile(ci: CanvasItem, rect: Rect2, cell: int, seed: int) -> void:
	var s := rect.size.x
	match cell:
		GridProblem.Cell.FREE:
			ci.draw_rect(rect, FREE)
			for k in 3:
				var h := absi(hash(seed * 7 + k))
				var p := rect.position + Vector2(0.2 + (h % 60) / 100.0, 0.2 + ((h >> 8) % 60) / 100.0) * s
				ci.draw_circle(p, s * 0.04, FREE_DOT)
		GridProblem.Cell.GRASS:
			ci.draw_rect(rect, GRASS)
			for k in 4:
				var h := absi(hash(seed * 13 + k))
				var base := rect.position + Vector2(0.15 + (h % 70) / 100.0, 0.55 + ((h >> 8) % 35) / 100.0) * s
				ci.draw_line(base, base + Vector2(-0.05, -0.18) * s, GRASS_BLADE, maxf(1.5, s * 0.04))
				ci.draw_line(base, base + Vector2(0.05, -0.2) * s, GRASS_BLADE, maxf(1.5, s * 0.04))
		GridProblem.Cell.DIFFICULT:
			ci.draw_rect(rect, MUD)
			ci.draw_circle(rect.position + Vector2(0.3, 0.35) * s, s * 0.14, MUD_PUDDLE)
			ci.draw_circle(rect.position + Vector2(0.68, 0.62) * s, s * 0.18, MUD_PUDDLE)
			ci.draw_circle(rect.position + Vector2(0.3, 0.75) * s, s * 0.08, MUD_PUDDLE)
		GridProblem.Cell.OBSTACLE:
			ci.draw_rect(rect, WALL)
			var w := maxf(1.0, s * 0.04)
			for row in 3:
				var y := rect.position.y + s * (row + 1) / 3.0
				ci.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), WALL_LINE, w)
				var offset := 0.5 if row % 2 == 0 else 0.25
				var x := rect.position.x + s * offset
				ci.draw_line(Vector2(x, y - s / 3.0), Vector2(x, y), WALL_LINE, w)
	ci.draw_rect(rect, Color(0, 0, 0, 0.12), false, 1.0)


## Casa azul: ponto de partida.
static func draw_start(ci: CanvasItem, rect: Rect2) -> void:
	var s := rect.size.x
	var c := rect.get_center()
	var roof := PackedVector2Array([c + Vector2(-0.34, -0.02) * s, c + Vector2(0, -0.34) * s, c + Vector2(0.34, -0.02) * s])
	ci.draw_colored_polygon(roof, START.darkened(0.2))
	ci.draw_rect(Rect2(c + Vector2(-0.25, -0.02) * s, Vector2(0.5, 0.32) * s), START)
	ci.draw_rect(Rect2(c + Vector2(-0.07, 0.1) * s, Vector2(0.14, 0.2) * s), Color.WHITE)


static func draw_player(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var bob := sin(t * 6.0) * s * 0.02
	c.y += bob
	_shadow(ci, c + Vector2(0, 0.38) * s, s)
	ci.draw_rect(Rect2(c + Vector2(-0.2, 0.02) * s, Vector2(0.4, 0.34) * s), PLAYER)  # camiseta
	ci.draw_circle(c + Vector2(0, -0.14) * s, s * 0.2, Color("f2c29b"))  # rosto
	ci.draw_arc(c + Vector2(0, -0.2) * s, s * 0.2, PI, TAU, 16, Color("4a2c16"), s * 0.08)  # cabelo
	ci.draw_circle(c + Vector2(-0.07, -0.15) * s, s * 0.03, Color.BLACK)
	ci.draw_circle(c + Vector2(0.07, -0.15) * s, s * 0.03, Color.BLACK)
	ci.draw_arc(c + Vector2(0, -0.09) * s, s * 0.07, 0.3, PI - 0.3, 8, Color.BLACK, maxf(1.0, s * 0.02))


static func draw_robot(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	_shadow(ci, c + Vector2(0, 0.38) * s, s)
	var body := Rect2(c + Vector2(-0.26, -0.22) * s, Vector2(0.52, 0.56) * s)
	ci.draw_rect(body, ROBOT)
	ci.draw_rect(Rect2(c + Vector2(-0.18, -0.14) * s, Vector2(0.36, 0.2) * s), Color("e8f4ff"))  # visor
	var blink := 0.2 if fmod(t, 3.0) < 0.15 else 1.0
	ci.draw_rect(Rect2(c + Vector2(-0.12, -0.1) * s, Vector2(0.07, 0.1 * blink) * s), Color("1b1b2f"))
	ci.draw_rect(Rect2(c + Vector2(0.05, -0.1) * s, Vector2(0.07, 0.1 * blink) * s), Color("1b1b2f"))
	ci.draw_line(c + Vector2(0, -0.22) * s, c + Vector2(0, -0.36) * s, ROBOT.darkened(0.3), maxf(1.5, s * 0.03))
	var glow := 0.6 + 0.4 * sin(t * 5.0)
	ci.draw_circle(c + Vector2(0, -0.38) * s, s * 0.06, Color(1.0, 0.3, 0.3, glow))


static func draw_mosquito(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var p := c + Vector2(cos(t * 3.1), sin(t * 4.3)) * s * 0.18
	var flap := 0.6 + 0.4 * absf(sin(t * 30.0))
	ci.draw_set_transform(p, 0, Vector2.ONE)
	ci.draw_circle(Vector2(-0.1, -0.06) * s, s * 0.09 * flap, Color(0.75, 0.9, 1.0, 0.8))
	ci.draw_circle(Vector2(0.1, -0.06) * s, s * 0.09 * flap, Color(0.75, 0.9, 1.0, 0.8))
	ci.draw_circle(Vector2.ZERO, s * 0.06, Color("222222"))
	ci.draw_circle(Vector2(0, 0.09) * s, s * 0.045, Color("222222"))
	for k in 3:  # listras brancas do Aedes aegypti
		ci.draw_line(Vector2(-0.04, 0.03 + k * 0.03) * s, Vector2(0.04, 0.03 + k * 0.03) * s, Color.WHITE, maxf(1.0, s * 0.012))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _shadow(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_set_transform(c, 0, Vector2(1, 0.3))
	ci.draw_circle(Vector2.ZERO, s * 0.26, Color(0, 0, 0, 0.18))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Ícone do criadouro. `full` = com água (antes de ser eliminado).
static func draw_focus(ci: CanvasItem, c: Vector2, s: float, focus_name: String, full := true) -> void:
	var water := Color("4aa3df") if full else Color(0, 0, 0, 0)
	match focus_key(focus_name):
		"pneu":
			ci.draw_circle(c, s * 0.34, Color("2b2b2b"))
			ci.draw_circle(c, s * 0.18, water if full else Color("777777"))
			ci.draw_arc(c, s * 0.27, 0, TAU, 24, Color("555555"), s * 0.03)
		"garrafa":
			ci.draw_rect(Rect2(c + Vector2(-0.14, -0.08) * s, Vector2(0.28, 0.42) * s), Color("7fc97f"))
			ci.draw_rect(Rect2(c + Vector2(-0.06, -0.3) * s, Vector2(0.12, 0.22) * s), Color("7fc97f"))
			if full:
				ci.draw_rect(Rect2(c + Vector2(-0.14, 0.12) * s, Vector2(0.28, 0.22) * s), water)
		"vaso":
			var pot := PackedVector2Array([c + Vector2(-0.24, -0.05) * s, c + Vector2(0.24, -0.05) * s, c + Vector2(0.17, 0.26) * s, c + Vector2(-0.17, 0.26) * s])
			ci.draw_colored_polygon(pot, Color("c96b3c"))
			ci.draw_rect(Rect2(c + Vector2(-0.34, 0.26) * s, Vector2(0.68, 0.08) * s), water if full else Color("b35a2e"))
			ci.draw_circle(c + Vector2(-0.08, -0.16) * s, s * 0.1, Color("3f9b3f"))
			ci.draw_circle(c + Vector2(0.09, -0.2) * s, s * 0.12, Color("4caf50"))
		"caixa":
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.18) * s, Vector2(0.6, 0.48) * s), Color("5aa9e6"))
			ci.draw_rect(Rect2(c + Vector2(-0.34, -0.26) * s, Vector2(0.68, 0.1) * s), Color("2f6fab"))
			if full:  # tampa torta: fresta com água
				ci.draw_rect(Rect2(c + Vector2(0.1, -0.2) * s, Vector2(0.2, 0.05) * s), water.lightened(0.3))
		"balde":
			var bucket := PackedVector2Array([c + Vector2(-0.26, -0.18) * s, c + Vector2(0.26, -0.18) * s, c + Vector2(0.18, 0.3) * s, c + Vector2(-0.18, 0.3) * s])
			ci.draw_colored_polygon(bucket, Color("e63946"))
			ci.draw_arc(c + Vector2(0, -0.18) * s, s * 0.26, PI, TAU, 16, Color("6b6b6b"), s * 0.03)
			if full:
				ci.draw_rect(Rect2(c + Vector2(-0.24, -0.18) * s, Vector2(0.48, 0.08) * s), water)
		_:
			ci.draw_rect(Rect2(c + Vector2(-0.28, -0.12) * s, Vector2(0.56, 0.4) * s), Color("f4a261"))
			if full:
				ci.draw_rect(Rect2(c + Vector2(-0.24, -0.08) * s, Vector2(0.48, 0.12) * s), water)
