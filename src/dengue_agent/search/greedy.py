"""Busca Gulosa (Greedy Best-First Search) — busca informada.

f(n) = h(n)

Expande sempre o nó com menor h — ou seja, o que PARECE mais próximo
do objetivo, ignorando quanto já foi gasto para chegar até ele.

NÃO é ótima: pode escolher um caminho ruim se a heurística "puxar"
para uma direção que depois se revela cara ou bloqueada.
NÃO é completa em espaços infinitos (aqui é completa porque o grid é
finito e usamos graph search).

Comparação com A*:
- A* pondera passado (g) e futuro estimado (h).
- Gulosa só olha o futuro estimado (h).
- Em cenários com muitos obstáculos e desvios longos, Gulosa costuma
  achar caminhos piores em custo, mas expande menos nós.
"""

from heapq import heappush, heappop
from itertools import count
from time import perf_counter

from ..grid import GridProblem
from ..models import Position
from .common import Node, SearchResult, reconstruct_path
from .heuristics import manhattan_weighted


def greedy_search(problem: GridProblem) -> SearchResult:
    start_time = perf_counter()

    root = Node(position=problem.initial_state)
    goal = problem.goal_state

    if problem.is_goal(root.position):
        elapsed_ms = (perf_counter() - start_time) * 1000
        return SearchResult(
            algorithm="Greedy",
            found=True,
            path=[root.position],
            cost=0,
            steps=0,
            expanded_states=0,
            generated_states=1,
            max_frontier_size=1,
            execution_time_ms=elapsed_ms,
            explored_order=[],
        )

    # Fronteira ordenada por (h, contador). Contador é desempate FIFO,
    # mesma razão do A*: evita comparar Nodes e mantém reprodutibilidade.
    counter = count()
    root_h = manhattan_weighted(root.position, goal)
    frontier: list[tuple[int, int, Node]] = [(root_h, next(counter), root)]

    # 'reached' aqui é como no BFS: marca na GERAÇÃO.
    # Diferença conceitual em relação ao A*:
    # - No A* usávamos 'best_g' porque um mesmo estado pode ser alcançado
    #   por caminhos de custos diferentes, e precisamos do melhor.
    # - Na Gulosa não nos importamos com custo do caminho — só com h,
    #   que só depende da posição. Se já geramos essa posição, qualquer
    #   novo caminho até ela seria empatado em h e não mudaria a decisão
    #   de expansão. Então basta um set de posições já vistas.
    reached: set[Position] = {root.position}

    generated = 1
    expanded = 0
    max_frontier = 1
    explored_order: list[Position] = []

    while frontier:
        _, _, node = heappop(frontier)

        expanded += 1
        explored_order.append(node.position)

        # Teste de objetivo na EXPANSÃO, por consistência com A* e Gulosa.
        # Na Gulosa isso não afeta otimalidade (que já não temos), então
        # a escolha é só estilística.
        if problem.is_goal(node.position):
            path = reconstruct_path(node)
            elapsed_ms = (perf_counter() - start_time) * 1000
            return SearchResult(
                algorithm="Greedy",
                found=True,
                path=path,
                cost=node.path_cost,
                steps=len(path) - 1,
                expanded_states=expanded,
                generated_states=generated,
                max_frontier_size=max_frontier,
                execution_time_ms=elapsed_ms,
                explored_order=explored_order,
            )

        for next_position, step_cost in problem.successors(node.position):
            if next_position in reached:
                continue

            reached.add(next_position)
            child = Node(
                position=next_position,
                parent=node,
                path_cost=node.path_cost + step_cost,
                depth=node.depth + 1,
            )
            generated += 1
            child_h = manhattan_weighted(next_position, goal)
            heappush(frontier, (child_h, next(counter), child))

        if len(frontier) > max_frontier:
            max_frontier = len(frontier)

    elapsed_ms = (perf_counter() - start_time) * 1000
    return SearchResult(
        algorithm="Greedy",
        found=False,
        expanded_states=expanded,
        generated_states=generated,
        max_frontier_size=max_frontier,
        execution_time_ms=elapsed_ms,
        explored_order=explored_order,
    )