extends SceneTree
## Uso: godot --headless --path bonus_godot --script res://tests/dump_results.gd
## Imprime, em JSON, o resultado das 4 buscas em GDScript para cada nível.
## tests/test_godot.py (na raiz do repositório) compara com o Python.


func _init() -> void:
	var out := {}
	for file in DirAccess.get_files_at("res://levels"):
		if not file.ends_with(".json"):
			continue
		var problem := GridProblem.from_file("res://levels/" + file)
		var results := {}
		for name in Search.NAMES:
			var r := Search.run(name, problem)
			var path := []
			for p in r["path"]:
				path.append([p.y, p.x])  # (linha, coluna), como no Python
			results[name] = {
				"found": r["found"], "steps": r["steps"], "cost": r["cost"],
				"expanded": r["expanded"], "generated": r["generated"],
				"max_frontier": r["max_frontier"], "path": path,
			}
		out[file] = results
	print("RESULTS_JSON " + JSON.stringify(out))
	quit()
