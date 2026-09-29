class_name GridProblem
extends RefCounted
## Mesmo modelo do projeto Python (grid.py): grade, custos e sucessores.
## Posições são Vector2i(coluna, linha), para casar com x/y da tela.

enum Cell { FREE, GRASS, DIFFICULT, OBSTACLE }

const COSTS := {Cell.FREE: 1, Cell.GRASS: 2, Cell.DIFFICULT: 4}
const SYMBOLS := {".": Cell.FREE, "G": Cell.GRASS, "D": Cell.DIFFICULT, "#": Cell.OBSTACLE, "S": Cell.FREE, "F": Cell.FREE}
## Ordem fixa igual à do Python: cima, direita, baixo, esquerda.
const MOVES: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var name := ""
var focus := "Foco de dengue"
var message := ""
var cols := 0
var rows := 0
var cells: Array = []  # cells[linha][coluna] -> Cell
var start := Vector2i.ZERO
var goal := Vector2i.ZERO


static func from_file(path: String) -> GridProblem:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Cenário inválido: %s" % path)
		return null
	return from_dict(data)


static func from_dict(data: Dictionary) -> GridProblem:
	var problem := GridProblem.new()
	problem.name = data.get("name", "Cenário")
	problem.focus = data.get("focus", "Foco de dengue")
	problem.message = data.get("message", "")
	var lines: Array = data["grid"]
	problem.rows = lines.size()
	problem.cols = String(lines[0]).length()
	for r in problem.rows:
		var line := String(lines[r])
		var row := []
		for c in problem.cols:
			var symbol := line[c]
			row.append(SYMBOLS[symbol])
			if symbol == "S":
				problem.start = Vector2i(c, r)
			elif symbol == "F":
				problem.goal = Vector2i(c, r)
		problem.cells.append(row)
	return problem


func to_dict() -> Dictionary:
	var lines := []
	var letters := {Cell.FREE: ".", Cell.GRASS: "G", Cell.DIFFICULT: "D", Cell.OBSTACLE: "#"}
	for r in rows:
		var line := ""
		for c in cols:
			var p := Vector2i(c, r)
			if p == start:
				line += "S"
			elif p == goal:
				line += "F"
			else:
				line += letters[cells[r][c]]
		lines.append(line)
	return {"name": name, "focus": focus, "message": message, "grid": lines}


func cell(p: Vector2i) -> int:
	return cells[p.y][p.x]


func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < cols and p.y < rows


func is_valid(p: Vector2i) -> bool:
	return inside(p) and cell(p) != Cell.OBSTACLE


func is_goal(p: Vector2i) -> bool:
	return p == goal


## O custo pertence à célula de destino do movimento.
func cost(p: Vector2i) -> int:
	return COSTS[cell(p)]


func successors(p: Vector2i) -> Array:
	var result := []
	for move in MOVES:
		var next := p + move
		if is_valid(next):
			result.append([next, cost(next)])
	return result


func min_step_cost() -> int:
	var lowest := 1 << 30
	for value in COSTS.values():
		lowest = mini(lowest, value)
	return lowest
