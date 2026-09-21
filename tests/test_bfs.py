"""Testes básicos de BFS."""

from dengue_agent.models import CellType, Position, Scenario
from dengue_agent.grid import GridProblem
from dengue_agent.search.bfs import breadth_first_search


def _make_scenario(grid_chars: list[str], start: Position, goal: Position) -> Scenario:
    """Converte uma grade de caracteres em Scenario.

    Mapeamento: '.' = FREE, '#' = OBSTACLE, 'g' = GRASS, 'd' = DIFFICULT.
    (Usei minúsculas para não confundir com o 'S' e 'G' do JSON real.)
    """
    mapping = {
        ".": CellType.FREE,
        "#": CellType.OBSTACLE,
        "g": CellType.GRASS,
        "d": CellType.DIFFICULT,
    }
    grid = [[mapping[c] for c in row] for row in grid_chars]
    return Scenario(name="test", message="", grid=grid, start=start, goal=goal)


def test_bfs_caminho_reto():
    """Grade livre 3x3, origem no canto e objetivo no canto oposto.
    Menor nº de passos é 4."""
    scenario = _make_scenario(
        [
            "...",
            "...",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = breadth_first_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 4
    assert result.path[0] == Position(0, 0)
    assert result.path[-1] == Position(2, 2)


def test_bfs_com_obstaculo():
    """Um obstáculo força o desvio; BFS ainda acha o menor nº de passos."""
    scenario = _make_scenario(
        [
            "...",
            ".#.",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = breadth_first_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 4  # tem que contornar o obstáculo


def test_bfs_sem_solucao():
    """Objetivo cercado por obstáculos — BFS deve terminar reportando falha."""
    scenario = _make_scenario(
        [
            "...",
            "###",
            "...",  # G aqui é só marcador visual; o goal é definido abaixo
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    # ajusta a célula do goal para FREE (não é obstáculo, mas está cercado)
    scenario.grid[2][2] = CellType.FREE
    result = breadth_first_search(GridProblem(scenario))
    assert not result.found
    assert result.path == []


def test_bfs_inicio_igual_objetivo():
    """Caso degenerado: já começa no objetivo."""
    scenario = _make_scenario(["..."], start=Position(0, 0), goal=Position(0, 0))
    result = breadth_first_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 0
    assert result.cost == 0
    assert result.path == [Position(0, 0)]