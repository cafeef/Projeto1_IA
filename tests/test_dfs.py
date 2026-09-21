"""Testes básicos de DFS."""

from dengue_agent.models import CellType, Position, Scenario
from dengue_agent.grid import GridProblem
from dengue_agent.search.dfs import depth_first_search


def _make_scenario(grid_chars: list[str], start: Position, goal: Position) -> Scenario:
    mapping = {
        ".": CellType.FREE,
        "#": CellType.OBSTACLE,
        "g": CellType.GRASS,
        "d": CellType.DIFFICULT,
    }
    grid = [[mapping[c] for c in row] for row in grid_chars]
    return Scenario(name="test", message="", grid=grid, start=start, goal=goal)


def test_dfs_encontra_solucao():
    """Grade livre — DFS acha ALGUM caminho, não necessariamente o mais curto."""
    scenario = _make_scenario(
        [
            "...",
            "...",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = depth_first_search(GridProblem(scenario))
    assert result.found
    assert result.path[0] == Position(0, 0)
    assert result.path[-1] == Position(2, 2)
    # NOTA: intencionalmente não checamos steps == 4. DFS pode achar
    # caminho mais longo, e isso é comportamento esperado.


def test_dfs_com_obstaculo():
    scenario = _make_scenario(
        [
            "...",
            ".#.",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = depth_first_search(GridProblem(scenario))
    assert result.found
    assert result.path[-1] == Position(2, 2)


def test_dfs_sem_solucao():
    scenario = _make_scenario(
        [
            "...",
            "###",
            "...",
        ],
        start=Position(0, 0),
        goal=Position(2, 2),
    )
    result = depth_first_search(GridProblem(scenario))
    assert not result.found


def test_dfs_inicio_igual_objetivo():
    scenario = _make_scenario(["..."], start=Position(0, 0), goal=Position(0, 0))
    result = depth_first_search(GridProblem(scenario))
    assert result.found
    assert result.steps == 0


def test_dfs_pode_ser_pior_que_bfs():
    """Documenta explicitamente que DFS não garante caminho mínimo.

    Numa grade 3x3 livre, o caminho mínimo tem 4 passos. Com a ordem de
    vizinhos N,L,S,O e pilha LIFO, DFS explora Oeste primeiro. Partindo
    de (0,0), Oeste é inválido, Sul é próximo — vai descer pela coluna 0
    até (2,0), depois direita até (2,2). Isso dá 4 passos também neste
    caso, mas em grids maiores a diferença aparece. O teste só confirma
    que DFS TERMINA e encontra caminho.
    """
    scenario = _make_scenario(
        [
            ".....",
            ".....",
            ".....",
            ".....",
            ".....",
        ],
        start=Position(0, 0),
        goal=Position(4, 4),
    )
    result = depth_first_search(GridProblem(scenario))
    assert result.found
    # steps >= 8 (mínimo) e sem loop infinito
    assert result.steps >= 8