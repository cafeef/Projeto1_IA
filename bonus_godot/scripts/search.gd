class_name Search
extends RefCounted
## BFS, DFS, Busca Gulosa e A* escritos à mão, sem o AStarGrid2D/NavigationServer
## da Godot. É a mesma lógica de src/dengue_agent/search/: mesma ordem de
## sucessores, mesmo desempate e mesmas contagens, então os resultados batem
## com os do Python (conferido por tests/run_tests.gd).

const NAMES := ["BFS", "DFS", "Gulosa", "A*"]


class SearchNode:
	var position: Vector2i
	var parent: SearchNode
	var g: int

	func _init(p: Vector2i, from: SearchNode = null, cost := 0) -> void:
		position = p
		parent = from
		g = cost


## Heap binário mínimo de [prioridade, contador, nó]. O contador desempata
## pela ordem de inserção, como a tupla (f, next(counter), node) do Python.
class MinHeap:
	var items: Array = []

	func size() -> int:
		return items.size()

	func push(priority: int, order: int, node: SearchNode) -> void:
		items.append([priority, order, node])
		var i := items.size() - 1
		while i > 0:
			var parent := (i - 1) / 2
			if not _less(items[i], items[parent]):
				break
			_swap(i, parent)
			i = parent

	func pop() -> SearchNode:
		var top: SearchNode = items[0][2]
		var last = items.pop_back()
		if not items.is_empty():
			items[0] = last
			var i := 0
			while true:
				var left := 2 * i + 1
				var right := left + 1
				var smallest := i
				if left < items.size() and _less(items[left], items[smallest]):
					smallest = left
				if right < items.size() and _less(items[right], items[smallest]):
					smallest = right
				if smallest == i:
					break
				_swap(i, smallest)
				i = smallest
		return top

	func _less(a: Array, b: Array) -> bool:
		return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])

	func _swap(i: int, j: int) -> void:
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp


static func run(algorithm: String, problem: GridProblem) -> Dictionary:
	match algorithm:
		"BFS":
			return bfs(problem)
		"DFS":
			return dfs(problem)
		"Gulosa":
			return greedy(problem)
		_:
			return astar(problem)


## Distância Manhattan ponderada pelo menor custo: admissível e consistente.
static func heuristic(problem: GridProblem, p: Vector2i) -> int:
	var d := absi(p.x - problem.goal.x) + absi(p.y - problem.goal.y)
	return d * problem.min_step_cost()


static func bfs(problem: GridProblem) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var root := SearchNode.new(problem.start)
	if problem.is_goal(root.position):
		return _found("BFS", root, 0, 1, 1, [], t0)
	var frontier: Array = [root]
	var head := 0  # fila FIFO: índice do próximo a sair
	var reached := {root.position: true}
	var generated := 1
	var expanded := 0
	var max_frontier := 1
	var explored: Array = []
	while head < frontier.size():
		var node: SearchNode = frontier[head]
		head += 1
		expanded += 1
		explored.append(node.position)
		for succ in problem.successors(node.position):
			var next: Vector2i = succ[0]
			if reached.has(next):
				continue
			var child := SearchNode.new(next, node, node.g + succ[1])
			generated += 1
			if problem.is_goal(next):  # BFS testa o objetivo na geração
				return _found("BFS", child, expanded, generated, max_frontier, explored, t0)
			reached[next] = true
			frontier.append(child)
		max_frontier = maxi(max_frontier, frontier.size() - head)
	return _not_found("BFS", expanded, generated, max_frontier, explored, t0)


static func dfs(problem: GridProblem) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var root := SearchNode.new(problem.start)
	if problem.is_goal(root.position):
		return _found("DFS", root, 0, 1, 1, [], t0)
	var frontier: Array = [root]  # pilha LIFO
	var visited := {}
	var generated := 1
	var expanded := 0
	var max_frontier := 1
	var explored: Array = []
	while not frontier.is_empty():
		var node: SearchNode = frontier.pop_back()
		if visited.has(node.position):  # duplicata: já expandido por outro caminho
			continue
		visited[node.position] = true
		expanded += 1
		explored.append(node.position)
		if problem.is_goal(node.position):
			return _found("DFS", node, expanded, generated, max_frontier, explored, t0)
		for succ in problem.successors(node.position):
			if visited.has(succ[0]):
				continue
			frontier.append(SearchNode.new(succ[0], node, node.g + succ[1]))
			generated += 1
		max_frontier = maxi(max_frontier, frontier.size())
	return _not_found("DFS", expanded, generated, max_frontier, explored, t0)


static func greedy(problem: GridProblem) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var root := SearchNode.new(problem.start)
	if problem.is_goal(root.position):
		return _found("Gulosa", root, 0, 1, 1, [], t0)
	var frontier := MinHeap.new()
	var order := 0
	frontier.push(heuristic(problem, root.position), order, root)
	var reached := {root.position: true}
	var generated := 1
	var expanded := 0
	var max_frontier := 1
	var explored: Array = []
	while frontier.size() > 0:
		var node := frontier.pop()
		expanded += 1
		explored.append(node.position)
		if problem.is_goal(node.position):
			return _found("Gulosa", node, expanded, generated, max_frontier, explored, t0)
		for succ in problem.successors(node.position):
			var next: Vector2i = succ[0]
			if reached.has(next):
				continue
			reached[next] = true
			generated += 1
			order += 1
			frontier.push(heuristic(problem, next), order, SearchNode.new(next, node, node.g + succ[1]))
		max_frontier = maxi(max_frontier, frontier.size())
	return _not_found("Gulosa", expanded, generated, max_frontier, explored, t0)


static func astar(problem: GridProblem) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var root := SearchNode.new(problem.start)
	if problem.is_goal(root.position):
		return _found("A*", root, 0, 1, 1, [], t0)
	var frontier := MinHeap.new()
	var order := 0
	frontier.push(heuristic(problem, root.position), order, root)
	var best_g := {root.position: 0}
	var generated := 1
	var expanded := 0
	var max_frontier := 1
	var explored: Array = []
	while frontier.size() > 0:
		var node := frontier.pop()
		if node.g > best_g[node.position]:  # entrada obsoleta no heap
			continue
		expanded += 1
		explored.append(node.position)
		if problem.is_goal(node.position):  # A* testa o objetivo na expansão
			return _found("A*", node, expanded, generated, max_frontier, explored, t0)
		for succ in problem.successors(node.position):
			var next: Vector2i = succ[0]
			var new_g: int = node.g + succ[1]
			if new_g < best_g.get(next, 1 << 30):
				best_g[next] = new_g
				generated += 1
				order += 1
				frontier.push(new_g + heuristic(problem, next), order, SearchNode.new(next, node, new_g))
		max_frontier = maxi(max_frontier, frontier.size())
	return _not_found("A*", expanded, generated, max_frontier, explored, t0)


static func _path(node: SearchNode) -> Array:
	var path: Array = []
	while node != null:
		path.push_front(node.position)
		node = node.parent
	return path


static func _found(name: String, node: SearchNode, expanded: int, generated: int, max_frontier: int, explored: Array, t0: int) -> Dictionary:
	var path := _path(node)
	return {
		"algorithm": name, "found": true, "path": path, "cost": node.g, "steps": path.size() - 1,
		"expanded": expanded, "generated": generated, "max_frontier": max_frontier,
		"time_ms": (Time.get_ticks_usec() - t0) / 1000.0, "explored": explored,
	}


static func _not_found(name: String, expanded: int, generated: int, max_frontier: int, explored: Array, t0: int) -> Dictionary:
	return {
		"algorithm": name, "found": false, "path": [], "cost": 0, "steps": 0,
		"expanded": expanded, "generated": generated, "max_frontier": max_frontier,
		"time_ms": (Time.get_ticks_usec() - t0) / 1000.0, "explored": explored,
	}
