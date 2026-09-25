"""Modelos simples usados pela grade e pelos algoritmos de busca."""

from dataclasses import dataclass
from enum import StrEnum


class CellType(StrEnum):
    FREE = "free"
    GRASS = "grass"
    DIFFICULT = "difficult"
    OBSTACLE = "obstacle"


@dataclass(frozen=True, order=True)
class Position:
    row: int
    col: int


@dataclass
class Scenario:
    """Um mapa pronto para ser resolvido pelo usuário ou pelo agente."""

    name: str
    message: str
    grid: list[list[CellType]]
    start: Position
    goal: Position
    # Criadouro representado pelo foco; dá título à mensagem educativa.
    focus: str = "Foco de dengue"

    @property
    def rows(self) -> int:
        return len(self.grid)

    @property
    def cols(self) -> int:
        return len(self.grid[0])
