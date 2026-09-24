"""Janela Arcade: apenas desenha o cenário e lê o teclado.

As regras de movimento e custo continuam no GridProblem; a interface
nunca decide nada sozinha.
"""

import arcade

from ..config import SCENARIOS_DIR
from ..grid import GridProblem
from ..models import CellType, Position
from ..player import Player
from ..scenarios import load_scenarios


WIDTH = 960
HEIGHT = 640
HEADER = 70  # faixa no topo reservada para o texto

COLORS = {
    CellType.FREE: (235, 230, 215),
    CellType.GRASS: (120, 190, 100),
    CellType.DIFFICULT: (150, 110, 70),
    CellType.OBSTACLE: (60, 60, 70),
}
GRID_LINE = (40, 40, 40)
START_COLOR = (50, 110, 220)
GOAL_COLOR = (210, 40, 40)
PLAYER_COLOR = (245, 150, 30)
TRAIL_COLOR = (245, 200, 60, 110)  # translúcido: o terreno continua visível

KEY_MOVES = {
    arcade.key.UP: (-1, 0), arcade.key.W: (-1, 0),
    arcade.key.RIGHT: (0, 1), arcade.key.D: (0, 1),
    arcade.key.DOWN: (1, 0), arcade.key.S: (1, 0),
    arcade.key.LEFT: (0, -1), arcade.key.A: (0, -1),
}

# Teclas 1..9 escolhem o cenário pela ordem alfabética dos arquivos.
SCENARIO_KEYS = [getattr(arcade.key, f"KEY_{n}") for n in range(1, 10)]


class GameWindow(arcade.Window):
    def __init__(self) -> None:
        super().__init__(WIDTH, HEIGHT, "Agente de Combate à Dengue")
        self.background_color = (25, 25, 30)
        self.scenarios = load_scenarios(SCENARIOS_DIR)
        self.title = arcade.Text("", 16, HEIGHT - 28, arcade.color.WHITE, 16)
        self.status = arcade.Text("", 16, HEIGHT - 54, arcade.color.LIGHT_GRAY, 13)
        self.select_scenario(0)

    def select_scenario(self, index: int) -> None:
        self.scenario = self.scenarios[index]
        self.problem = GridProblem(self.scenario)
        self.player = Player(self.problem)
        rows, cols = self.scenario.rows, self.scenario.cols
        # A célula se ajusta ao maior mapa sem cortar; a grade fica centralizada.
        self.tile = min(WIDTH // cols, (HEIGHT - HEADER) // rows)
        self.offset_x = (WIDTH - cols * self.tile) // 2
        self.offset_y = (HEIGHT - HEADER - rows * self.tile) // 2
        total = len(self.scenarios)
        self.title.text = (
            f"[{index + 1}/{total}] {self.scenario.name}   (teclas 1-{total} trocam o cenário)"
        )

    def cell_origin(self, position: Position) -> tuple[int, int]:
        """Canto inferior esquerdo da célula. No Arcade o Y cresce para cima."""
        x = self.offset_x + position.col * self.tile
        y = self.offset_y + (self.scenario.rows - 1 - position.row) * self.tile
        return x, y

    def draw_marker(self, position: Position, color) -> None:
        x, y = self.cell_origin(position)
        half = self.tile / 2
        arcade.draw_circle_filled(x + half, y + half, half * 0.6, color)

    def on_draw(self) -> None:
        self.clear()
        for row, line in enumerate(self.scenario.grid):
            for col, cell in enumerate(line):
                x, y = self.cell_origin(Position(row, col))
                arcade.draw_lbwh_rectangle_filled(x, y, self.tile, self.tile, COLORS[cell])
                arcade.draw_lbwh_rectangle_outline(x, y, self.tile, self.tile, GRID_LINE)
        for position in self.player.path:
            x, y = self.cell_origin(position)
            arcade.draw_lbwh_rectangle_filled(x, y, self.tile, self.tile, TRAIL_COLOR)
        self.draw_marker(self.scenario.start, START_COLOR)
        self.draw_marker(self.scenario.goal, GOAL_COLOR)
        self.draw_marker(self.player.position, PLAYER_COLOR)

        p = self.player
        self.status.text = (
            f"Usuário: passos={p.steps}  custo={p.cost}  tempo={p.elapsed_s:.1f}s"
            + ("   CHEGOU!" if p.finished else "")
            + "      setas/WASD movem · R reinicia"
        )
        self.title.draw()
        self.status.draw()

    def on_key_press(self, key: int, modifiers: int) -> None:
        if key in KEY_MOVES:
            self.player.move(*KEY_MOVES[key])
        elif key == arcade.key.R:
            self.player = Player(self.problem)
        elif key in SCENARIO_KEYS:
            index = SCENARIO_KEYS.index(key)
            if index < len(self.scenarios):
                self.select_scenario(index)
