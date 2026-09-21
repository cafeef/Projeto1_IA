"""Heurísticas para os algoritmos informados (Gulosa e A*).

Uma heurística h(n) estima o custo restante entre a posição atual e o
objetivo. Para ser útil, ela precisa ser barata de calcular e o mais
próxima possível do custo real.

Duas propriedades importantes:

- ADMISSÍVEL: h(n) nunca superestima o custo real até o objetivo.
  Garante que A* encontra solução ótima.

- CONSISTENTE (ou monotônica): para todo nó n e sucessor n',
  h(n) <= custo(n, n') + h(n').
  Garante que a primeira vez que A* expande um nó, já é com o menor g(n)
  possível — então não precisamos reabrir nós fechados.

Consistente implica admissível. A recíproca não vale.
"""

from ..grid import COSTS
from ..models import Position


def manhattan(a: Position, b: Position) -> int:
    """Distância Manhattan pura: |dx| + |dy|.

    Retorna o NÚMERO MÍNIMO de passos ortogonais entre a e b, ignorando
    obstáculos. Como o problema só permite movimentos N/L/S/O, esse é o
    limite inferior teórico da quantidade de passos.
    """
    return abs(a.row - b.row) + abs(a.col - b.col)


# Menor custo de terreno TRANSITÁVEL no ambiente. Excluímos OBSTACLE
# porque não é uma célula que pode ser pisada — seu "custo" é infinito
# na prática (movimento proibido). Com FREE=1, GRASS=2, DIFFICULT=4,
# o mínimo é 1.
_MIN_STEP_COST = min(COSTS.values())


def manhattan_weighted(a: Position, b: Position) -> int:
    """Manhattan multiplicada pelo menor custo possível de um movimento.

    Justificativa de admissibilidade:
    - Todo caminho de a até b tem no mínimo `manhattan(a, b)` passos.
    - Todo passo custa no mínimo `_MIN_STEP_COST`.
    - Logo, o custo real >= manhattan(a, b) * _MIN_STEP_COST.
    - Portanto h nunca superestima. ADMISSÍVEL.

    Justificativa de consistência:
    - Sucessores diferem em exatamente 1 passo Manhattan.
    - h(n) - h(n') pertence a {-_MIN_STEP_COST, +_MIN_STEP_COST}.
    - custo(n, n') >= _MIN_STEP_COST.
    - Logo h(n) <= custo(n, n') + h(n'). CONSISTENTE.

    Consequência prática: A* nunca precisa reabrir nó fechado com esta h.
    """
    return manhattan(a, b) * _MIN_STEP_COST