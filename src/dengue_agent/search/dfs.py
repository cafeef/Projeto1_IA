"""Busca em Profundidade (DFS) — busca sem informação, aprofunda antes de alternar.

Ideia: expande primeiro o filho mais recente. Usa uma pilha LIFO como
fronteira. NÃO garante caminho mais curto nem de menor custo — encontra
"algum" caminho, e a qualidade dele depende brutalmente da ordem em que
os vizinhos são gerados (definida em grid.py: N, L, S, O).

Esta implementação é graph search (usa conjunto de visitados). DFS em
árvore, sem controle de visitados, poderia entrar em loop infinito
numa grade com ciclos.
"""

from time import perf_counter

from ..grid import GridProblem
from ..models import Position
from .common import Node, SearchResult, reconstruct_path


def depth_first_search(problem: GridProblem) -> SearchResult:
    start_time = perf_counter()

    root = Node(position=problem.initial_state)

    if problem.is_goal(root.position):
        elapsed_ms = (perf_counter() - start_time) * 1000
        return SearchResult(
            algorithm="DFS",
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

    # Fronteira: pilha LIFO. Uma list comum basta — append/pop no final.
    frontier: list[Node] = [root]

    # 'visited' guarda posições JÁ EXPANDIDAS (não geradas, como BFS).
    # Motivo: em DFS, marcar como visitado só na expansão preserva o
    # comportamento "aprofunda até bater na parede, depois volta".
    # Se marcássemos na geração, a fronteira teria caminhos que nunca
    # seriam desenvolvidos, distorcendo a métrica de tamanho máximo.
    visited: set[Position] = set()

    generated = 1
    expanded = 0
    max_frontier = 1
    explored_order: list[Position] = []

    while frontier:
        node = frontier.pop()  # LIFO: pega o mais recente

        # Um nó pode aparecer na pilha várias vezes antes de ser expandido
        # (foi empurrado, algum outro caminho o alcançou primeiro).
        # Ignoramos duplicatas na hora da expansão.
        if node.position in visited:
            continue

        visited.add(node.position)
        expanded += 1
        explored_order.append(node.position)

        # Teste de objetivo na EXPANSÃO (não na geração como BFS).
        # Em DFS, o primeiro caminho encontrado não é necessariamente ótimo,
        # então não faz diferença testar antes ou depois — mas testar na
        # expansão mantém o algoritmo simétrico com A* e Gulosa.
        if problem.is_goal(node.position):
            path = reconstruct_path(node)
            elapsed_ms = (perf_counter() - start_time) * 1000
            return SearchResult(
                algorithm="DFS",
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
            if next_position in visited:
                continue

            child = Node(
                position=next_position,
                parent=node,
                path_cost=node.path_cost + step_cost,
                depth=node.depth + 1,
            )
            generated += 1
            frontier.append(child)

        if len(frontier) > max_frontier:
            max_frontier = len(frontier)

    elapsed_ms = (perf_counter() - start_time) * 1000
    return SearchResult(
        algorithm="DFS",
        found=False,
        expanded_states=expanded,
        generated_states=generated,
        max_frontier_size=max_frontier,
        execution_time_ms=elapsed_ms,
        explored_order=explored_order,
    )