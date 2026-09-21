"""Utilitários para execução em lote dos algoritmos de busca.

Este módulo é intencionalmente enxuto. A Pessoa 4 é responsável pelo
pipeline de experimentos: iteração sobre cenários, coleta de métricas,
serialização em JSON e geração de tabelas/gráficos. Aqui apenas
oferecemos uma forma padronizada de executar os quatro algoritmos
sobre uma mesma instância do problema.
"""

from .grid import GridProblem
from .models import Scenario
from .search.astar import astar_search
from .search.bfs import breadth_first_search
from .search.common import SearchResult
from .search.dfs import depth_first_search
from .search.greedy import greedy_search


def run_all(scenario: Scenario) -> list[SearchResult]:
    """Executa os quatro algoritmos sobre o mesmo cenário.

    Retorna a lista de resultados na ordem BFS, DFS, Gulosa, A*.
    Cada SearchResult contém caminho, custo, passos, estados expandidos,
    estados gerados, tamanho máximo da fronteira, tempo de execução e
    ordem de exploração.

    A ordem de retorno é fixa para facilitar comparação entre execuções.
    """
    problem = GridProblem(scenario)
    return [
        breadth_first_search(problem),
        depth_first_search(problem),
        greedy_search(problem),
        astar_search(problem),
    ]