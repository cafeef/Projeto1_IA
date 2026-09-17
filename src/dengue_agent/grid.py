"""Regras da grade compartilhadas pelos algoritmos e pela interface."""

from .models import CellType, Position, Scenario


COSTS = {
    CellType.FREE: 1,
    CellType.GRASS: 2,
    CellType.DIFFICULT: 4,
}

# A ordem fixa deixa BFS e DFS reproduzíveis durante a demonstração.
MOVES = ((-1, 0), (0, 1), (1, 0), (0, -1))


class GridProblem:
    def __init__(self, scenario: Scenario) -> None:
        self.scenario = scenario

    @property
    def initial_state(self) -> Position:
        return self.scenario.start

    @property
    def goal_state(self) -> Position:
        return self.scenario.goal

    def is_goal(self, position: Position) -> bool:
        return position == self.goal_state

    def cell(self, position: Position) -> CellType:
        return self.scenario.grid[position.row][position.col]

    def is_valid(self, position: Position) -> bool:
        inside = (
            0 <= position.row < self.scenario.rows
            and 0 <= position.col < self.scenario.cols
        )
        return inside and self.cell(position) is not CellType.OBSTACLE

    def cost(self, position: Position) -> int:
        # O custo pertence à célula de destino do movimento.
        return COSTS[self.cell(position)]

    def successors(self, position: Position) -> list[tuple[Position, int]]:
        neighbors = []
        for row_change, col_change in MOVES:
            next_position = Position(position.row + row_change, position.col + col_change)
            if self.is_valid(next_position):
                neighbors.append((next_position, self.cost(next_position)))
        return neighbors
