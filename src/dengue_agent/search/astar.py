"""A* — busca informada com custo acumulado + heurística.

f(n) = g(n) + h(n)
  g(n): custo real do início até n
  h(n): estimativa do custo de n até o objetivo

Expande sempre o nó de menor f. Com heurística admissível e graph search,
encontra a solução de MENOR CUSTO. Se a heurística também for consistente,
não precisa reabrir nós já fechados.
"""

from heapq import heappush, heappop
from itertools import count
from time import perf_counter

from ..grid import GridProblem
from ..models import Position
from .common import Node, SearchResult, reconstruct_path
from .heuristics import manhattan_weighted


def astar_search(problem: GridProblem) -> SearchResult:
    start_time = perf_counter()

    root = Node(position=problem.initial_state)
    goal = problem.goal_state

    if problem.is_goal(root.position):
        elapsed_ms = (perf_counter() - start_time) * 1000
        return SearchResult(
            algorithm="A*",
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

    # Fronteira: min-heap ordenada por (f, contador).
    # O contador é desempate: quando dois nós têm mesmo f, o mais antigo
    # sai primeiro. Também evita que o heap tente comparar Nodes entre si
    # (Node não é ordenável) e mantém a busca reprodutível.
    counter = count()
    root_f = 0 + manhattan_weighted(root.position, goal)
    frontier: list[tuple[int, int, Node]] = [(root_f, next(counter), root)]

    # 'best_g' guarda o menor g conhecido para cada posição.
    # Serve para dois propósitos:
    # 1. Descartar nós da fronteira que ficaram obsoletos (já achamos
    #    um caminho melhor para a mesma posição — heapq não permite
    #    remover no meio, então marcamos por custo).
    # 2. Decidir se um sucessor vale a pena ser inserido.
    best_g: dict[Position, int] = {root.position: 0}

    generated = 1
    expanded = 0
    max_frontier = 1
    explored_order: list[Position] = []

    while frontier:
        f, _, node = heappop(frontier)

        # Nó obsoleto: já achamos caminho melhor para esta posição
        # depois que este nó foi inserido. Descarta silenciosamente.
        if node.path_cost > best_g[node.position]:
            continue

        expanded += 1
        explored_order.append(node.position)

        # Teste de objetivo na EXPANSÃO (não na geração).
        # Isto é crítico para otimalidade do A*: o primeiro nó GERADO
        # que é objetivo pode não ser o de menor custo. Só temos garantia
        # de otimalidade quando o objetivo é EXPANDIDO (retirado do topo
        # do heap com o menor f).
        if problem.is_goal(node.position):
            path = reconstruct_path(node)
            elapsed_ms = (perf_counter() - start_time) * 1000
            return SearchResult(
                algorithm="A*",
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
            new_g = node.path_cost + step_cost

            # Só insere se for MELHOR que qualquer caminho conhecido
            # até esta posição. Isso é o graph search do A*.
            if new_g < best_g.get(next_position, float("inf")):
                best_g[next_position] = new_g
                child = Node(
                    position=next_position,
                    parent=node,
                    path_cost=new_g,
                    depth=node.depth + 1,
                )
                generated += 1
                child_f = new_g + manhattan_weighted(next_position, goal)
                heappush(frontier, (child_f, next(counter), child))

        if len(frontier) > max_frontier:
            max_frontier = len(frontier)

    elapsed_ms = (perf_counter() - start_time) * 1000
    return SearchResult(
        algorithm="A*",
        found=False,
        expanded_states=expanded,
        generated_states=generated,
        max_frontier_size=max_frontier,
        execution_time_ms=elapsed_ms,
        explored_order=explored_order,
    )