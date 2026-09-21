"""Busca em Largura (BFS) — busca sem informação, explora por níveis.

Ideia: expande primeiro os nós mais próximos da origem (em número de
passos). Usa uma fila FIFO como fronteira. Em grafo com pesos positivos
uniformes, BFS acha o caminho de MENOR NÚMERO DE PASSOS, mas não
necessariamente o de menor CUSTO quando há terrenos diferentes.
"""

from collections import deque
from time import perf_counter

from ..grid import GridProblem
from ..models import Position
from .common import Node, SearchResult, reconstruct_path


def breadth_first_search(problem: GridProblem) -> SearchResult:
    start_time = perf_counter()

    # Nó inicial: sem pai, custo zero, profundidade zero.
    root = Node(position=problem.initial_state)

    # Caso raro: começar já no objetivo.
    if problem.is_goal(root.position):
        elapsed_ms = (perf_counter() - start_time) * 1000
        return SearchResult(
            algorithm="BFS",
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

    # Fronteira: fila FIFO. Guarda Nodes.
    frontier: deque[Node] = deque([root])

    # 'reached' guarda toda posição JÁ colocada na fronteira ou expandida.
    # É o que faz esta ser uma graph search (evita revisitar).
    # Em BFS, a primeira vez que alcançamos uma posição já é o caminho
    # com menor número de passos até ela; não vale a pena revisitar.
    reached: set[Position] = {root.position}

    # Contadores das métricas exigidas pelo enunciado.
    generated = 1        # o nó inicial já conta como gerado
    expanded = 0
    max_frontier = 1
    explored_order: list[Position] = []

    while frontier:
        node = frontier.popleft()
        expanded += 1
        explored_order.append(node.position)

        for next_position, step_cost in problem.successors(node.position):
            if next_position in reached:
                continue

            child = Node(
                position=next_position,
                parent=node,
                path_cost=node.path_cost + step_cost,
                depth=node.depth + 1,
            )
            generated += 1

            # Teste de objetivo na GERAÇÃO (padrão para BFS):
            # assim que o objetivo aparece como filho, terminamos.
            # É correto porque BFS visita por níveis: o primeiro nó-filho
            # que for objetivo tem, por construção, o menor nº de passos.
            if problem.is_goal(next_position):
                path = reconstruct_path(child)
                elapsed_ms = (perf_counter() - start_time) * 1000
                return SearchResult(
                    algorithm="BFS",
                    found=True,
                    path=path,
                    cost=child.path_cost,
                    steps=len(path) - 1,
                    expanded_states=expanded,
                    generated_states=generated,
                    max_frontier_size=max_frontier,
                    execution_time_ms=elapsed_ms,
                    explored_order=explored_order,
                )

            reached.add(next_position)
            frontier.append(child)

        if len(frontier) > max_frontier:
            max_frontier = len(frontier)

    # Fronteira esvaziou sem achar o objetivo: sem solução.
    elapsed_ms = (perf_counter() - start_time) * 1000
    return SearchResult(
        algorithm="BFS",
        found=False,
        expanded_states=expanded,
        generated_states=generated,
        max_frontier_size=max_frontier,
        execution_time_ms=elapsed_ms,
        explored_order=explored_order,
    )