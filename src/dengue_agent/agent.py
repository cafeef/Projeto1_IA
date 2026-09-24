"""Reprodução animada de um SearchResult.

A busca roda inteira antes (e mede o próprio tempo); aqui só revelamos
no ritmo da tela os estados explorados e depois o caminho. Não depende
do Arcade, então pode ser testado sem janela.
"""

from .models import Position
from .search.common import SearchResult


EXPLORE_STEP_S = 0.03  # tempo para revelar cada estado expandido
MOVE_STEP_S = 0.12  # tempo para o agente andar uma célula


class AgentRun:
    def __init__(self, result: SearchResult, start: Position) -> None:
        self.result = result
        self.start = start
        self.explored_shown = 0
        self.path_index = 0
        self._elapsed = 0.0

    @property
    def exploring(self) -> bool:
        return self.explored_shown < len(self.result.explored_order)

    @property
    def finished(self) -> bool:
        if self.exploring:
            return False
        return not self.result.found or self.path_index == len(self.result.path) - 1

    @property
    def position(self) -> Position:
        if self.result.found:
            return self.result.path[self.path_index]
        return self.start

    def update(self, dt: float) -> None:
        self._elapsed += dt
        while not self.finished:
            step = EXPLORE_STEP_S if self.exploring else MOVE_STEP_S
            if self._elapsed < step:
                return
            self._elapsed -= step
            if self.exploring:
                self.explored_shown += 1
            else:
                self.path_index += 1
