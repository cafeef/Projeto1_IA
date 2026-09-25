import csv
import json
from pathlib import Path

from dengue_agent.config import OFFICIAL_SCENARIOS
from dengue_agent.experiments import (
    load_human_runs,
    main,
    markdown_table,
    run_experiments,
)
from dengue_agent.scenarios import load_scenario


MAPS = Path(__file__).parents[1] / "scenarios"


def partida(scenario: str, cost: int, found: bool = True) -> dict:
    return {
        "scenario": scenario, "method": "Usuário", "found": found, "gave_up": not found,
        "path": [[1, 1], [1, 2]], "steps": 1, "cost": cost, "time_s": 2.5,
    }


def gravar(tmp_path: Path, partidas: list[dict]) -> Path:
    arquivo = tmp_path / "human_runs.jsonl"
    arquivo.write_text("\n".join(json.dumps(p) for p in partidas) + "\n", encoding="utf-8")
    return arquivo


def test_vale_a_primeira_partida_de_cada_cenario(tmp_path: Path) -> None:
    partidas = [partida("A", 10), partida("B", 7), partida("A", 3)]
    runs = load_human_runs(gravar(tmp_path, partidas))
    assert runs["A"].cost == 10  # a repetição não substitui a primeira tentativa
    assert runs["B"].time_ms == 2500
    assert runs["A"].expanded_states is None


def test_sem_arquivo_humano(tmp_path: Path) -> None:
    assert load_human_runs(tmp_path / "nao_existe.jsonl") == {}


def test_quinze_execucoes_nos_cenarios_oficiais(tmp_path: Path) -> None:
    scenarios = [load_scenario(MAPS / name) for name in OFFICIAL_SCENARIOS]
    humanos = load_human_runs(gravar(tmp_path, [partida(s.name, 1) for s in scenarios]))
    rows = run_experiments(scenarios, humanos, repeats=1)

    assert len(rows) == 15
    assert [r.method for r in rows[:5]] == ["Usuário", "BFS", "DFS", "Gulosa", "A*"]
    assert all(r.found for r in rows)


def test_cenario_complexo_separa_passos_de_custo() -> None:
    scenario = load_scenario(MAPS / OFFICIAL_SCENARIOS[-1])
    rows = {r.method: r for r in run_experiments([scenario], {}, repeats=1)}
    assert rows["BFS"].steps < rows["A*"].steps
    assert rows["A*"].cost < rows["BFS"].cost
    assert rows["A*"].cost == min(r.cost for r in rows.values())


def test_tabela_markdown_usa_traco_para_o_usuario(tmp_path: Path) -> None:
    humano = load_human_runs(gravar(tmp_path, [partida("X", 4)]))["X"]
    tabela = markdown_table([humano])
    assert "| X | Usuário | 1 | 4 | 2.5 s | — | — | — |" in tabela


def test_main_gera_arquivos(tmp_path: Path) -> None:
    main(["--no-charts", "--repeats", "1", "--human-runs", str(tmp_path / "vazio.jsonl"),
          "--out", str(tmp_path)])
    with (tmp_path / "experimentos.csv").open(encoding="utf-8") as file:
        linhas = list(csv.DictReader(file))
    assert len(linhas) == 12
    assert json.loads((tmp_path / "experimentos.json").read_text(encoding="utf-8"))
    assert (tmp_path / "tabela_experimentos.md").exists()

