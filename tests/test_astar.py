"""Testes de A* — foca em otimalidade e no diferencial vs BFS."""

from dengue_agent.models import CellType, Position, Scenario
from dengue_agent.grid import GridProblem
from dengue_agent.search.astar import astar_search
from dengue_agent.search.bfs import breadth_first_search


def _make_scenario(grid_chars: list[str], start: Position, goal: Position) -> Scenario:
    mapping = {
        ".": CellType.FREE,
        "#": CellType.OBSTACLE,
        "g": CellType.GRASS,
        "d": CellType.DIFFICULT,
    }
    grid = [[mapping[c] for c in row] for row in grid_chars]
    return Scenario(name="test", message="", grid=grid, start=start, goal=goal)


def test_astar_caminho_reto():
    scenario = _make_scenario(
        [
            "...",
            "...",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = astar_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 4
    assert result.cost == 4  # 4 passos em FREE, custo 1 cada


def test_astar_com_obstaculo():
    scenario = _make_scenario(
        [
            "...",
            ".#.",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = astar_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 4
    assert result.cost == 4


def test_astar_prefere_menor_custo_nao_menor_passos():
    """A* deve escolher caminho mais longo em passos se for mais barato.

    Layout:
      . d d .      (linha 0: start em (0,0), goal em (0,3), duas células difíceis no meio)
      . . . .      (linha 1: tudo livre)

    Menor em passos (por cima): 3 passos, custos das células de destino =
      d(4) + d(4) + FREE(1) = 9

    Menor em custo (descer, contornar, subir): 5 passos, custos =
      FREE(1) x 5 = 5

    A* deve escolher o de custo 5.
    """
    scenario = _make_scenario(
        [
            ".dd.",
            "....",
        ],
        start=Position(0, 0),
        goal=Position(0, 3),
    )
    result = astar_search(GridProblem(scenario))
    bfs_result = breadth_first_search(GridProblem(scenario))

    assert result.found
    assert bfs_result.steps == 3
    assert bfs_result.cost == 9
    assert result.cost == 5
    assert result.steps == 5


def test_astar_iguala_bfs_em_custo_e_expande_menos_com_obstaculos():
    """Em cenário com obstáculos, A* deve podar direções ruins.

    Grade com um corredor forçado: a heurística orienta A* para o corredor,
    enquanto BFS explora igualmente todas as direções.
    """
    scenario = _make_scenario(
        [
            "..........",
            "########..",
            "..........",
            "..########",
            "..........",
        ],
        start=Position(0, 0),
        goal=Position(4, 9),
    )
    astar_result = astar_search(GridProblem(scenario))
    bfs_result = breadth_first_search(GridProblem(scenario))

    assert astar_result.found and bfs_result.found
    # Otimalidade: mesmo custo.
    assert astar_result.cost == bfs_result.cost
    # Eficiência: A* expande no máximo o que BFS expande. A heurística
    # orienta a busca ao longo do corredor em vez de se espalhar.
    assert astar_result.expanded_states <= bfs_result.expanded_states


def test_astar_expande_menos_com_terreno_caro():
    """Com terreno caro, a heurística admissível ainda garante otimalidade.

    Layout:
      . . . . . . . . . .    (linha 0: livre)
      d d d d d d d d d d    (linha 1: tudo difícil)
      . . . . . . . . . .    (linha 2: livre)

    Menor caminho é reto pela linha 0. A* e BFS devem achar mesmo custo.
    """
    scenario = _make_scenario(
        [
            "..........",
            "dddddddddd",
            "..........",
        ],
        start=Position(0, 0),
        goal=Position(0, 9),
    )
    astar_result = astar_search(GridProblem(scenario))
    bfs_result = breadth_first_search(GridProblem(scenario))

    assert astar_result.found and bfs_result.found
    assert astar_result.cost == bfs_result.cost == 9


def test_astar_sem_solucao():
    scenario = _make_scenario(
        [
            "...",
            "###",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = astar_search(GridProblem(scenario))
    assert not result.found


def test_astar_inicio_igual_objetivo():
    scenario = _make_scenario(["..."], start=Position(0, 0), goal=Position(0, 0))
    result = astar_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 0
    assert result.cost == 0