"""Estruturas comuns aos quatro algoritmos de busca.

Este módulo NÃO implementa busca. Ele define:
- Node: o "envelope" que embrulha uma posição durante a busca,
  guardando de onde ela veio (para reconstruir o caminho no final).
- SearchResult: o formato padronizado que todos os algoritmos retornam,
  contendo caminho e todas as métricas exigidas pelo enunciado.
- reconstruct_path: sobe pela cadeia de pais de um Node até a raiz
  e devolve a lista de posições do começo ao fim.
"""

from dataclasses import dataclass, field
from typing import Optional

from ..models import Position


@dataclass
class Node:
    """Um nó da árvore de busca.

    - position: a célula da grade que este nó representa.
    - parent: o Node anterior no caminho (None só para o nó inicial).
    - path_cost: g(n), custo acumulado do início até esta posição.
    - depth: profundidade na árvore de busca. Útil para DFS e debug.
    """

    position: Position
    parent: Optional["Node"] = None
    path_cost: int = 0
    depth: int = 0


@dataclass
class SearchResult:
    """Resultado padronizado de qualquer algoritmo de busca.

    Todos os campos vêm direto dos requisitos do enunciado (seção 2.4.2)
    mais o que a interface precisa para animar a exploração.
    """

    algorithm: str
    found: bool
    path: list[Position] = field(default_factory=list)
    cost: int = 0
    steps: int = 0
    expanded_states: int = 0
    generated_states: int = 0
    max_frontier_size: int = 0
    execution_time_ms: float = 0.0
    explored_order: list[Position] = field(default_factory=list)


def reconstruct_path(node: Node) -> list[Position]:
    """Sobe pela cadeia de pais e devolve o caminho da origem ao nó.

    Cada algoritmo, ao encontrar o objetivo, chama esta função no Node
    do objetivo. Como cada Node aponta para o seu pai, basta caminhar
    para trás até o nó inicial (cujo parent é None) e inverter a lista.
    """
    path: list[Position] = []
    current: Optional[Node] = node
    while current is not None:
        path.append(current.position)
        current = current.parent
    path.reverse()
    return path