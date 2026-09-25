"""Experimentos obrigatórios: 3 execuções humanas + 12 algorítmicas.

Uso, a partir da raiz do repositório:
    uv run dengue-experimentos              # tabelas + gráficos
    uv run dengue-experimentos --no-charts  # só CSV/JSON/Markdown

As execuções humanas vêm de results/human_runs.jsonl, gravado pela
interface (uv run dengue). Vale a PRIMEIRA partida registrada em cada
cenário oficial, conforme o enunciado: uma única execução manual, para
que o usuário não aprenda o mapa repetindo a missão.

Os gráficos usam matplotlib apenas para desenhar; nenhuma lógica de busca
depende dele.
"""

import argparse
import csv
import json
import statistics
from dataclasses import asdict, dataclass, field
from pathlib import Path

from .config import HUMAN_RUNS_FILE, OFFICIAL_SCENARIOS, RESULTS_DIR, SCENARIOS_DIR
from .metrics import run_all
from .models import CellType, Scenario
from .scenarios import load_scenario

HUMAN = "Usuário"
METHODS = (HUMAN, "BFS", "DFS", "Gulosa", "A*")


@dataclass
class ExperimentRow:
    """Uma execução (humana ou algorítmica) de um cenário."""

    scenario: str
    method: str
    found: bool
    steps: int
    cost: int
    time_ms: float
    # Métricas de busca não se aplicam ao usuário: ficam None.
    expanded_states: int | None = None
    generated_states: int | None = None
    max_frontier_size: int | None = None
    path: list[tuple[int, int]] = field(default_factory=list)


def algorithm_rows(scenario: Scenario, repeats: int = 5) -> list[ExperimentRow]:
    """Roda BFS, DFS, Gulosa e A* no cenário.

    Caminho, custo e contagens são determinísticos, então vêm da primeira
    rodada. O tempo é a mediana de `repeats` rodadas, porque uma medição
    isolada de décimos de milissegundo é dominada por ruído do sistema.
    """
    rounds = [run_all(scenario) for _ in range(max(repeats, 1))]
    rows = []
    for i, result in enumerate(rounds[0]):
        times = [r[i].execution_time_ms for r in rounds]
        rows.append(
            ExperimentRow(
                scenario=scenario.name,
                method=result.algorithm,
                found=result.found,
                steps=result.steps,
                cost=result.cost,
                time_ms=statistics.median(times),
                expanded_states=result.expanded_states,
                generated_states=result.generated_states,
                max_frontier_size=result.max_frontier_size,
                path=[(p.row, p.col) for p in result.path],
            )
        )
    return rows


def load_human_runs(path: Path = HUMAN_RUNS_FILE) -> dict[str, ExperimentRow]:
    """Primeira partida registrada de cada cenário, indexada pelo nome."""
    runs: dict[str, ExperimentRow] = {}
    if not path.exists():
        return runs
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        if record["scenario"] in runs:
            continue
        runs[record["scenario"]] = ExperimentRow(
            scenario=record["scenario"],
            method=HUMAN,
            found=record["found"],
            steps=record["steps"],
            cost=record["cost"],
            time_ms=record["time_s"] * 1000,
            path=[tuple(p) for p in record["path"]],
        )
    return runs


def run_experiments(
    scenarios: list[Scenario],
    human_runs: dict[str, ExperimentRow],
    repeats: int = 5,
) -> list[ExperimentRow]:
    """Monta a tabela completa: por cenário, usuário (se houver) e os 4 algoritmos."""
    rows = []
    for scenario in scenarios:
        if scenario.name in human_runs:
            rows.append(human_runs[scenario.name])
        rows.extend(algorithm_rows(scenario, repeats))
    return rows


# ---------------------------------------------------------------- exportação


def write_csv(rows: list[ExperimentRow], path: Path) -> None:
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow([
            "cenario", "metodo", "encontrou", "passos", "custo", "tempo_ms",
            "expandidos", "gerados", "fronteira_max", "caminho",
        ])
        for r in rows:
            writer.writerow([
                r.scenario, r.method, r.found, r.steps, r.cost, f"{r.time_ms:.4f}",
                _blank(r.expanded_states), _blank(r.generated_states),
                _blank(r.max_frontier_size),
                " ".join(f"({row},{col})" for row, col in r.path),
            ])


def write_json(rows: list[ExperimentRow], path: Path) -> None:
    data = [asdict(r) for r in rows]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def markdown_table(rows: list[ExperimentRow]) -> str:
    """Tabela no formato do Apêndice A, pronta para colar no relatório."""
    lines = [
        "| Cenário | Método | Passos | Custo | Tempo | Expandidos | Gerados | Fronteira máx. |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for r in rows:
        if r.method == HUMAN:
            time = f"{r.time_ms / 1000:.1f} s"
        else:
            time = f"{r.time_ms:.3f} ms"
        steps = r.steps if r.found else "—"
        cost = r.cost if r.found else "—"
        lines.append(
            f"| {r.scenario} | {r.method} | {steps} | {cost} | {time} | "
            f"{_dash(r.expanded_states)} | {_dash(r.generated_states)} | "
            f"{_dash(r.max_frontier_size)} |"
        )
    return "\n".join(lines) + "\n"


def _blank(value: int | None) -> str:
    return "" if value is None else str(value)


def _dash(value: int | None) -> str:
    return "—" if value is None else str(value)


# ------------------------------------------------------------------ gráficos

# Uma cor fixa por método, igual em todos os gráficos.
METHOD_COLORS = {
    HUMAN: "#f5961e",
    "BFS": "#3b75c4",
    "DFS": "#8a8a8a",
    "Gulosa": "#2e9e5b",
    "A*": "#8c3cc8",
}
TERRAIN_COLORS = {
    CellType.FREE: "#ebe6d7",
    CellType.GRASS: "#b6dca8",
    CellType.DIFFICULT: "#b48c64",
    CellType.OBSTACLE: "#3c3c46",
}


def plot_metrics(rows: list[ExperimentRow], out_dir: Path) -> list[Path]:
    """Um gráfico de barras agrupadas por métrica: cenários no eixo X."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    scenarios = list(dict.fromkeys(r.scenario for r in rows))
    charts = [
        ("custo", "Custo total do caminho", lambda r: r.cost, True),
        ("passos", "Passos até o foco", lambda r: r.steps, True),
        ("expandidos", "Estados expandidos", lambda r: r.expanded_states, False),
        ("gerados", "Estados gerados", lambda r: r.generated_states, False),
        ("fronteira", "Tamanho máximo da fronteira", lambda r: r.max_frontier_size, False),
        ("tempo", "Tempo de execução do algoritmo (ms, mediana)", lambda r: r.time_ms, False),
    ]
    saved = []
    for slug, title, value, with_human in charts:
        methods = [m for m in METHODS if with_human or m != HUMAN]
        methods = [m for m in methods if any(r.method == m for r in rows)]
        width = 0.8 / len(methods)
        fig, ax = plt.subplots(figsize=(9, 4.5))
        for i, method in enumerate(methods):
            xs, ys = [], []
            for s, scenario in enumerate(scenarios):
                row = next((r for r in rows if r.scenario == scenario and r.method == method), None)
                if row is None or not row.found:
                    continue
                xs.append(s - 0.4 + width * (i + 0.5))
                ys.append(value(row))
            bars = ax.bar(xs, ys, width, label=method, color=METHOD_COLORS[method])
            ax.bar_label(bars, fmt="%.3g" if slug == "tempo" else "%d", fontsize=8, padding=2)
        ax.set_xticks(range(len(scenarios)), scenarios)
        ax.set_title(title)
        ax.spines[["top", "right"]].set_visible(False)
        ax.legend(frameon=False, ncols=len(methods), loc="upper left", fontsize=9)
        ax.margins(y=0.2)
        fig.tight_layout()
        path = out_dir / f"grafico_{slug}.png"
        fig.savefig(path, dpi=150)
        plt.close(fig)
        saved.append(path)
    return saved


def plot_paths(scenario: Scenario, rows: list[ExperimentRow], path: Path) -> None:
    """Mapa do cenário com o caminho de cada método, lado a lado."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import ListedColormap

    order = list(CellType)
    cmap = ListedColormap([TERRAIN_COLORS[c] for c in order])
    image = [[order.index(cell) for cell in line] for line in scenario.grid]
    runs = [r for m in METHODS for r in rows if r.scenario == scenario.name and r.method == m]

    fig, axes = plt.subplots(1, len(runs), figsize=(3.2 * len(runs), 3.4), squeeze=False)
    for ax, run in zip(axes[0], runs):
        ax.imshow(image, cmap=cmap, vmin=0, vmax=len(order) - 1)
        if run.path:
            rs, cs = zip(*run.path)
            ax.plot(cs, rs, color=METHOD_COLORS[run.method], linewidth=2.5)
        ax.plot(scenario.start.col, scenario.start.row, "o", color="#1f5fd0", markersize=7)
        ax.plot(scenario.goal.col, scenario.goal.row, "X", color="#d02828", markersize=9)
        label = f"custo {run.cost} · {run.steps} passos" if run.found else "sem rota"
        ax.set_title(f"{run.method}\n{label}", fontsize=9)
        ax.set_xticks([])
        ax.set_yticks([])
    fig.suptitle(scenario.name, fontsize=11)
    fig.tight_layout()
    fig.savefig(path, dpi=150)
    plt.close(fig)


# --------------------------------------------------------------------- main


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Executa os experimentos obrigatórios.")
    parser.add_argument("--no-charts", action="store_true", help="não gera os gráficos PNG")
    parser.add_argument("--repeats", type=int, default=5, help="rodadas para a mediana do tempo")
    parser.add_argument("--human-runs", type=Path, default=HUMAN_RUNS_FILE)
    parser.add_argument("--out", type=Path, default=RESULTS_DIR)
    args = parser.parse_args(argv)

    scenarios = [load_scenario(SCENARIOS_DIR / name) for name in OFFICIAL_SCENARIOS]
    human_runs = load_human_runs(args.human_runs)
    rows = run_experiments(scenarios, human_runs, args.repeats)

    args.out.mkdir(parents=True, exist_ok=True)
    write_csv(rows, args.out / "experimentos.csv")
    write_json(rows, args.out / "experimentos.json")
    table = markdown_table(rows)
    (args.out / "tabela_experimentos.md").write_text(table, encoding="utf-8")
    print(table)

    missing = [s.name for s in scenarios if s.name not in human_runs]
    humans = len(scenarios) - len(missing)
    print(f"Execuções: {humans} humanas + {len(rows) - humans} algorítmicas = {len(rows)}")
    if missing:
        print("Faltam execuções humanas (jogue com `uv run dengue`):", ", ".join(missing))

    if not args.no_charts:
        saved = plot_metrics(rows, args.out)
        for i, scenario in enumerate(scenarios, start=1):
            path = args.out / f"caminhos_cenario{i}.png"
            plot_paths(scenario, rows, path)
            saved.append(path)
        print("Gráficos:", ", ".join(p.name for p in saved))


if __name__ == "__main__":
    main()
