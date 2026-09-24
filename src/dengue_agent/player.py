"""Usuário humano: anda pela grade e registra as métricas da missão.

Não depende do Arcade, então pode ser testado sem abrir janela. Todas as
regras (limites, obstáculos, custo) vêm do GridProblem.
"""

from time import perf_counter

from .grid import GridProblem
from .models import Position


class Player:
    def __init__(self, problem: GridProblem) -> None:
        self.problem = problem
        self.position = problem.initial_state
        self.path: list[Position] = [self.position]
        self.cost = 0
        self._start: float | None = None
        self._end: float | None = None

    @property
    def steps(self) -> int:
        return len(self.path) - 1

    @property
    def finished(self) -> bool:
        return self._end is not None

    @property
    def elapsed_s(self) -> float:
        """Tempo desde o primeiro movimento; congela ao chegar no foco."""
        if self._start is None:
            return 0.0
        end = self._end if self._end is not None else perf_counter()
        return end - self._start

    def move(self, d_row: int, d_col: int) -> bool:
        """Tenta andar uma célula. Retorna False se o movimento for inválido."""
        if self.finished:
            return False
        target = Position(self.position.row + d_row, self.position.col + d_col)
        if not self.problem.is_valid(target):
            return False

        if self._start is None:
            self._start = perf_counter()
        self.position = target
        self.path.append(target)
        self.cost += self.problem.cost(target)
        if self.problem.is_goal(target):
            self._end = perf_counter()
        return True
