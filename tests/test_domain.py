import json
from pathlib import Path

import pytest

from dengue_agent.grid import GridProblem
from dengue_agent.models import Position
from dengue_agent.scenarios import load_scenario, load_scenarios


MAPS = Path(__file__).parents[1] / "scenarios"


def test_cenarios() -> None:
    scenarios = load_scenarios(MAPS)
    assert len(scenarios) == 6
    assert scenarios[0].name == "Quintal simples"


def test_vizinhos() -> None:
    problem = GridProblem(load_scenario(MAPS / "01_simple.json"))
    assert problem.successors(Position(1, 1)) == [
        (Position(1, 2), 1),
        (Position(2, 1), 1),
    ]
    assert not problem.is_valid(Position(0, 0))


def test_mapa_invalido(tmp_path: Path) -> None:
    path = tmp_path / "bad.json"
    path.write_text(json.dumps({"name": "Teste", "message": "", "grid": ["S."]}))
    with pytest.raises(ValueError, match="S e F"):
        load_scenario(path)


def test_rota_mais_barata() -> None:
    problem = GridProblem(load_scenario(MAPS / "05_cost_tradeoff.json"))
    direct_cost = sum(problem.cost(Position(1, col)) for col in range(2, 19))
    longer_path = [Position(2, 1), Position(3, 1)]
    longer_path += [Position(3, col) for col in range(2, 19)]
    longer_path += [Position(2, 18), Position(1, 18)]

    assert len(longer_path) > 17
    assert sum(problem.cost(position) for position in longer_path) < direct_cost
