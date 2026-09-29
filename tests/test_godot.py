"""Confere o jogo bônus em Godot contra o projeto principal.

- Os níveis de bonus_godot/levels/ devem ser cópias exatas de scenarios/.
- As buscas em GDScript devem produzir o mesmo caminho e as mesmas métricas
  que as buscas em Python. Este teste só roda se houver um executável da Godot
  4.5+ (variável GODOT_BIN ou `godot` no PATH).
"""

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

from dengue_agent.metrics import run_all
from dengue_agent.scenarios import load_scenario

ROOT = Path(__file__).parents[1]
GODOT_DIR = ROOT / "bonus_godot"
SCENARIOS = sorted((ROOT / "scenarios").glob("*.json"))


def test_niveis_iguais_aos_cenarios() -> None:
    levels = sorted(p.name for p in (GODOT_DIR / "levels").glob("*.json"))
    assert levels == [p.name for p in SCENARIOS]
    for scenario in SCENARIOS:
        copy = GODOT_DIR / "levels" / scenario.name
        assert json.loads(copy.read_text("utf-8")) == json.loads(scenario.read_text("utf-8"))


def godot_bin() -> str | None:
    return os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")


@pytest.mark.skipif(godot_bin() is None, reason="Godot não encontrada (defina GODOT_BIN)")
def test_buscas_gdscript_iguais_ao_python() -> None:
    godot = godot_bin()
    subprocess.run([godot, "--headless", "--path", str(GODOT_DIR), "--import"],
                   capture_output=True, timeout=300)
    out = subprocess.run(
        [godot, "--headless", "--path", str(GODOT_DIR), "--script", "res://tests/dump_results.gd"],
        capture_output=True, text=True, timeout=120,
    ).stdout
    line = next(l for l in out.splitlines() if l.startswith("RESULTS_JSON "))
    godot_results = json.loads(line.removeprefix("RESULTS_JSON "))

    for scenario_path in SCENARIOS:
        for py in run_all(load_scenario(scenario_path)):
            gd = godot_results[scenario_path.name][py.algorithm]
            label = f"{scenario_path.name} {py.algorithm}"
            assert gd["found"] == py.found, label
            assert gd["path"] == [[p.row, p.col] for p in py.path], label
            assert (gd["steps"], gd["cost"]) == (py.steps, py.cost), label
            assert gd["expanded"] == py.expanded_states, label
            assert gd["generated"] == py.generated_states, label
            assert gd["max_frontier"] == py.max_frontier_size, label


@pytest.mark.skipif(godot_bin() is None, reason="Godot não encontrada (defina GODOT_BIN)")
def test_jogo_responde_ao_teclado() -> None:
    godot = godot_bin()
    subprocess.run([godot, "--headless", "--path", str(GODOT_DIR), "--import"],
                   capture_output=True, timeout=300)
    run = subprocess.run(
        [godot, "--headless", "--path", str(GODOT_DIR), "--script", "res://tests/smoke_test.gd"],
        capture_output=True, text=True, timeout=120,
    )
    assert "FALHA" not in run.stdout, run.stdout
    assert run.stdout.count("ok   ") == 10, run.stdout
    assert run.returncode == 0


def test_frases_dos_focos_iguais_aos_cenarios() -> None:
    """As falas gravadas dos focos precisam bater com o texto dos cenários."""
    frases = json.loads((GODOT_DIR / "audio" / "frases.json").read_text("utf-8"))
    for scenario in SCENARIOS:
        data = json.loads(scenario.read_text("utf-8"))
        assert data["focus"] in frases.values(), data["focus"]
        assert data["message"] in frases.values(), data["message"]
