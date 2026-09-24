"""Janela Arcade: apenas desenha o cenário e lê o teclado.

As regras de movimento e custo continuam no GridProblem; a interface
nunca decide nada sozinha.
"""

import arcade

from ..agent import AgentRun
from ..config import HUMAN_RUNS_FILE, SCENARIOS_DIR
from ..grid import GridProblem
from ..models import CellType, Position
from ..player import Player
from ..scenarios import load_scenarios
from ..search.astar import astar_search
from ..search.bfs import breadth_first_search
from ..search.dfs import depth_first_search
from ..search.greedy import greedy_search


WIDTH = 960
HEIGHT = 640
HEADER = 90  # faixa no topo reservada para o texto

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
AGENT_COLOR = (140, 60, 200)
# Camadas translúcidas: o terreno continua visível por baixo.
TRAIL_COLOR = (245, 200, 60, 110)
EXPLORED_COLOR = (80, 160, 255, 90)
AGENT_PATH_COLOR = (140, 60, 200, 120)
PANEL_COLOR = (20, 20, 28)
PANEL_W, PANEL_H = 820, 330

KEY_MOVES = {
    arcade.key.UP: (-1, 0), arcade.key.W: (-1, 0),
    arcade.key.RIGHT: (0, 1), arcade.key.D: (0, 1),
    arcade.key.DOWN: (1, 0), arcade.key.S: (1, 0),
    arcade.key.LEFT: (0, -1), arcade.key.A: (0, -1),
}

# Segurar uma seta: 1 passo imediato, espera REPEAT_DELAY_S e repete a cada REPEAT_S.
REPEAT_DELAY_S = 0.25
REPEAT_S = 0.09

ALGORITHMS = [
    ("BFS", breadth_first_search),
    ("DFS", depth_first_search),
    ("Gulosa", greedy_search),
    ("A*", astar_search),
]

# Teclas 1..9 escolhem o cenário pela ordem alfabética dos arquivos.
SCENARIO_KEYS = [getattr(arcade.key, f"KEY_{n}") for n in range(1, 10)]


class GameWindow(arcade.Window):
    def __init__(self) -> None:
        super().__init__(WIDTH, HEIGHT, "Agente de Combate à Dengue")
        self.background_color = (25, 25, 30)
        self.scenarios = load_scenarios(SCENARIOS_DIR)
        self.algorithm_index = len(ALGORITHMS) - 1  # começa no A*
        self.held_key: int | None = None
        self.hold_timer = 0.0
        self.title = arcade.Text("", 16, HEIGHT - 28, arcade.color.WHITE, 16)
        self.status = arcade.Text("", 16, HEIGHT - 52, arcade.color.LIGHT_GRAY, 13)
        self.agent_status = arcade.Text("", 16, HEIGHT - 74, arcade.color.LIGHT_GRAY, 13)
        self.select_scenario(0)

    def select_scenario(self, index: int) -> None:
        self.scenario = self.scenarios[index]
        self.problem = GridProblem(self.scenario)
        self.reset()
        rows, cols = self.scenario.rows, self.scenario.cols
        # A célula se ajusta ao maior mapa sem cortar; a grade fica centralizada.
        self.tile = min(WIDTH // cols, (HEIGHT - HEADER) // rows)
        self.offset_x = (WIDTH - cols * self.tile) // 2
        self.offset_y = (HEIGHT - HEADER - rows * self.tile) // 2
        total = len(self.scenarios)
        self.title.text = (
            f"[{index + 1}/{total}] {self.scenario.name}   (teclas 1-{total} trocam o cenário)"
        )

    def reset(self) -> None:
        self.player = Player(self.problem)
        self.player_saved = False
        self.agent: AgentRun | None = None
        self.summary: list[arcade.Text] | None = None

    @property
    def mission_over(self) -> bool:
        return self.player.done and self.agent is not None and self.agent.finished

    def start_agent(self) -> None:
        self.summary = None
        _, search = ALGORITHMS[self.algorithm_index]
        # A busca roda inteira aqui e mede o próprio tempo; a animação vem depois.
        self.agent = AgentRun(search(self.problem), self.problem.initial_state)

    def cell_origin(self, position: Position) -> tuple[int, int]:
        """Canto inferior esquerdo da célula. No Arcade o Y cresce para cima."""
        x = self.offset_x + position.col * self.tile
        y = self.offset_y + (self.scenario.rows - 1 - position.row) * self.tile
        return x, y

    def fill_cells(self, positions, color) -> None:
        for position in positions:
            x, y = self.cell_origin(position)
            arcade.draw_lbwh_rectangle_filled(x, y, self.tile, self.tile, color)

    def draw_marker(self, position: Position, color, size: float = 0.6) -> None:
        x, y = self.cell_origin(position)
        half = self.tile / 2
        arcade.draw_circle_filled(x + half, y + half, half * size, color)

    def on_update(self, delta_time: float) -> None:
        if self.agent:
            self.agent.update(delta_time)
        if self.held_key is not None:
            self.hold_timer -= delta_time
            while self.hold_timer <= 0:
                self.player.move(*KEY_MOVES[self.held_key])
                self.hold_timer += REPEAT_S
        # Um ponto só cobre toque, tecla segurada e desistência.
        if self.player.done and not self.player_saved:
            self.player.save(HUMAN_RUNS_FILE, self.scenario.name)
            self.player_saved = True

    def on_draw(self) -> None:
        self.clear()
        for row, line in enumerate(self.scenario.grid):
            for col, cell in enumerate(line):
                x, y = self.cell_origin(Position(row, col))
                arcade.draw_lbwh_rectangle_filled(x, y, self.tile, self.tile, COLORS[cell])
                arcade.draw_lbwh_rectangle_outline(x, y, self.tile, self.tile, GRID_LINE)

        agent = self.agent
        if agent:
            self.fill_cells(agent.result.explored_order[: agent.explored_shown], EXPLORED_COLOR)
            if not agent.exploring:
                self.fill_cells(agent.result.path, AGENT_PATH_COLOR)
        self.fill_cells(self.player.path, TRAIL_COLOR)

        self.draw_marker(self.scenario.start, START_COLOR)
        self.draw_marker(self.scenario.goal, GOAL_COLOR)
        if agent:
            self.draw_marker(agent.position, AGENT_COLOR)
        # Menor que o agente: se os dois estiverem na mesma célula, ambos aparecem.
        self.draw_marker(self.player.position, PLAYER_COLOR, size=0.35)

        p = self.player
        self.status.text = (
            f"Usuário: passos={p.steps}  custo={p.cost}  tempo={p.elapsed_s:.1f}s"
            + ("   CHEGOU!" if p.finished else "   DESISTIU" if p.gave_up else "")
            + (" (salvo em results/)" if self.player_saved else "")
            + "      setas/WASD movem · X desiste · R reinicia"
        )
        self.agent_status.text = self.agent_text()
        self.title.draw()
        self.status.draw()
        self.agent_status.draw()

        if self.mission_over:
            if self.summary is None:
                self.summary = self.build_summary()
            left, bottom = (WIDTH - PANEL_W) / 2, (HEIGHT - HEADER - PANEL_H) / 2
            arcade.draw_lbwh_rectangle_filled(left, bottom, PANEL_W, PANEL_H, PANEL_COLOR)
            arcade.draw_lbwh_rectangle_outline(left, bottom, PANEL_W, PANEL_H, arcade.color.WHITE, 2)
            for text in self.summary:
                text.draw()

    def build_summary(self) -> list[arcade.Text]:
        """Painel final: mensagem educativa e comparação usuário x agente."""
        p, r = self.player, self.agent.result
        name, _ = ALGORITHMS[self.algorithm_index]
        left = (WIDTH - PANEL_W) / 2
        top = (HEIGHT - HEADER + PANEL_H) / 2
        center = WIDTH / 2
        white, gray = arcade.color.WHITE, arcade.color.LIGHT_GRAY

        title = "Missão concluída!" if p.finished or r.found else "Missão encerrada"
        texts = [
            arcade.Text(title, center, top - 40, white, 22, anchor_x="center", bold=True),
            # ponytail: uma linha só (as mensagens atuais têm < 100 caracteres);
            # usar multiline se aparecer mensagem maior que o painel.
            arcade.Text(self.scenario.message, center, top - 80, (255, 230, 150), 14, anchor_x="center"),
        ]

        user_label = "Usuário" + (" (desistiu)" if p.gave_up else "")
        agent_label = f"Agente {name}" + ("" if r.found else " (sem rota)")
        rows = [
            ("", "Passos", "Custo", "Tempo", "Expandidos", "Gerados", "Fronteira"),
            (user_label, p.steps, p.cost, f"{p.elapsed_s:.1f} s", "—", "—", "—"),
            (
                agent_label,
                r.steps if r.found else "—",
                r.cost if r.found else "—",
                f"{r.execution_time_ms:.3f} ms",
                r.expanded_states, r.generated_states, r.max_frontier_size,
            ),
        ]
        columns = [left + 30] + [left + 230 + i * 95 for i in range(6)]
        for i, row in enumerate(rows):
            y = top - 175 - i * 34
            color = gray if i == 0 else white
            for x, value in zip(columns, row):
                texts.append(arcade.Text(str(value), x, y, color, 14))

        footer = "R joga de novo · TAB/ESPAÇO testa outro algoritmo · 1-6 troca o cenário"
        texts.append(arcade.Text(footer, center, top - PANEL_H + 24, gray, 12, anchor_x="center"))
        return texts

    def agent_text(self) -> str:
        name, _ = ALGORITHMS[self.algorithm_index]
        if not self.agent:
            return f"Agente [{name}]: ESPAÇO inicia · TAB troca algoritmo"
        r = self.agent.result
        metrics = (
            f"expandidos={r.expanded_states}  gerados={r.generated_states}  "
            f"fronteira={r.max_frontier_size}  tempo={r.execution_time_ms:.3f}ms"
        )
        if not r.found:
            return f"Agente [{name}]: SEM ROTA  {metrics}"
        text = f"Agente [{name}]: passos={r.steps}  custo={r.cost}  {metrics}"
        return text + ("   CHEGOU!" if self.agent.finished else "")

    def on_key_press(self, key: int, modifiers: int) -> None:
        if key in KEY_MOVES:
            self.player.move(*KEY_MOVES[key])
            self.held_key = key  # a última tecla apertada manda
            self.hold_timer = REPEAT_DELAY_S
        elif key == arcade.key.X:
            self.player.give_up()
        elif key == arcade.key.SPACE:
            self.start_agent()
        elif key == arcade.key.TAB:
            self.algorithm_index = (self.algorithm_index + 1) % len(ALGORITHMS)
            self.agent = None
            self.summary = None
        elif key == arcade.key.R:
            self.reset()
        elif key in SCENARIO_KEYS:
            index = SCENARIO_KEYS.index(key)
            if index < len(self.scenarios):
                self.select_scenario(index)

    def on_key_release(self, key: int, modifiers: int) -> None:
        if key == self.held_key:
            self.held_key = None
