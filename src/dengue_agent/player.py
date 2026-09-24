"""Usuário humano: anda pela grade e registra as métricas da missão.

Não depende do Arcade, então pode ser testado sem abrir janela. Todas as
regras (limites, obstáculos, custo) vêm do GridProblem.
"""

import json
from datetime import datetime
from pathlib import Path
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
        self.gave_up = False

    @property
    def steps(self) -> int:
        return len(self.path) - 1

    @property
    def finished(self) -> bool:
        """Chegou ao foco."""
        return self.problem.is_goal(self.position)

    @property
    def done(self) -> bool:
        """Missão do usuário encerrada: chegou ou desistiu."""
        return self.finished or self.gave_up

    @property
    def elapsed_s(self) -> float:
        """Tempo desde o primeiro movimento; congela ao chegar ou desistir."""
        if self._start is None:
            return 0.0
        end = self._end if self._end is not None else perf_counter()
        return end - self._start

    def move(self, d_row: int, d_col: int) -> bool:
        """Tenta andar uma célula. Retorna False se o movimento for inválido."""
        if self.done:
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

    def give_up(self) -> None:
        """Encerra sem chegar (ex.: cenário sem rota). O tempo congela aqui."""
        if self.done:
            return
        self.gave_up = True
        if self._start is not None:
            self._end = perf_counter()

    def save(self, path: Path, scenario_name: str) -> None:
        """Acrescenta esta partida como uma linha JSON (formato JSON Lines)."""
        record = {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "scenario": scenario_name,
            "method": "Usuário",
            "found": self.finished,
            "gave_up": self.gave_up,
            "path": [[p.row, p.col] for p in self.path],
            "steps": self.steps,
            "cost": self.cost,
            "time_s": round(self.elapsed_s, 3),
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as file:
            file.write(json.dumps(record, ensure_ascii=False) + "\n")
