"""Testes de Busca Gulosa — foca em NÃO-otimalidade e velocidade."""

from dengue_agent.models import CellType, Position, Scenario
from dengue_agent.grid import GridProblem
from dengue_agent.search.greedy import greedy_search
from dengue_agent.search.astar import astar_search


def _make_scenario(grid_chars: list[str], start: Position, goal: Position) -> Scenario:
    mapping = {
        ".": CellType.FREE,
        "#": CellType.OBSTACLE,
        "g": CellType.GRASS,
        "d": CellType.DIFFICULT,
    }
    grid = [[mapping[c] for c in row] for row in grid_chars]
    return Scenario(name="test", message="", grid=grid, start=start, goal=goal)


def test_greedy_encontra_solucao():
    scenario = _make_scenario(
        [
            "...",
            "...",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = greedy_search(GridProblem(scenario))
    assert result.found
    assert result.path[0] == Position(0, 0)
    assert result.path[-1] == Position(2, 2)


def test_greedy_com_obstaculo():
    scenario = _make_scenario(
        [
            "...",
            ".#.",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = greedy_search(GridProblem(scenario))
    assert result.found
    assert result.path[-1] == Position(2, 2)


def test_greedy_pode_ser_pior_que_astar_em_custo():
    """Cenário construído para armar cilada para a Gulosa.

    Layout:
      S d d d G
      . . . . .

    Gulosa vê que ir direto (para a direita) reduz Manhattan mais rápido,
    então segue reto pela linha 0 e paga o custo alto do terreno difícil.
    A* percebe que descer, contornar e subir custa menos no total.

    Custos:
      Gulosa (S -> d -> d -> d -> G): custo 4+4+4+1 = 13
      A*     (S -> baixo -> 3x direita -> cima -> ... -> G): mais barato

    O teste só exige que a Gulosa NÃO seja melhor que A* em custo.
    """
    scenario = _make_scenario(
        [
            ".ddd.",
            ".....",
        ],
        start=Position(0, 0),
        goal=Position(0, 4),
    )
    greedy_result = greedy_search(GridProblem(scenario))
    astar_result = astar_search(GridProblem(scenario))

    assert greedy_result.found and astar_result.found
    # A* é ótimo, Gulosa >= A* em custo.
    assert greedy_result.cost >= astar_result.cost
    # No cenário construído, a diferença de fato ocorre:
    assert greedy_result.cost > astar_result.cost


def test_greedy_sem_solucao():
    scenario = _make_scenario(
        [
            "...",
            "###",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = greedy_search(GridProblem(scenario))
    assert not result.found


def test_greedy_inicio_igual_objetivo():
    scenario = _make_scenario(["..."], start=Position(0, 0), goal=Position(0, 0))
    result = greedy_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 0
    assert result.cost == 0