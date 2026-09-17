"""Carregamento dos mapas JSON."""

import json
from pathlib import Path

from .models import CellType, Position, Scenario


SYMBOLS = {
    ".": CellType.FREE,
    "G": CellType.GRASS,
    "D": CellType.DIFFICULT,
    "#": CellType.OBSTACLE,
    "S": CellType.FREE,
    "F": CellType.FREE,
}


def load_scenario(path: str | Path) -> Scenario:
    """Lê um arquivo JSON e transforma sua grade em objetos do domínio."""
    with Path(path).open(encoding="utf-8") as file:
        data = json.load(file)

    grid, start, goal = _read_grid(data["grid"])
    return Scenario(data["name"], data["message"], grid, start, goal)


def load_scenarios(folder: str | Path) -> list[Scenario]:
    """Carrega todos os mapas JSON do diretório em ordem alfabética."""
    return [load_scenario(path) for path in sorted(Path(folder).glob("*.json"))]


def _read_grid(lines: list[str]):
    if not lines or any(len(line) != len(lines[0]) for line in lines):
        raise ValueError("A grade deve ter linhas do mesmo tamanho.")

    start = goal = None
    grid = []
    for row, line in enumerate(lines):
        cells = []
        for col, symbol in enumerate(line):
            if symbol not in SYMBOLS:
                raise ValueError(f"Símbolo inválido: {symbol}")
            # S e F são marcadores visuais; no domínio, ambos são células livres.
            cells.append(SYMBOLS[symbol])
            if symbol == "S":
                start = Position(row, col)
            elif symbol == "F":
                goal = Position(row, col)
        grid.append(cells)

    if start is None or goal is None:
        raise ValueError("A grade precisa de S e F.")
    return grid, start, goal
