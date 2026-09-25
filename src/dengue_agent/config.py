"""Caminhos compartilhados da aplicação."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = PROJECT_ROOT / "scenarios"
RESULTS_DIR = PROJECT_ROOT / "results"
HUMAN_RUNS_FILE = RESULTS_DIR / "human_runs.jsonl"  # uma linha JSON por partida

# Cenários usados nos experimentos obrigatórios (simples, intermediário e complexo).
# Os demais mapas continuam jogáveis, mas ficam fora das 15 execuções.
OFFICIAL_SCENARIOS = ("01_simple.json", "02_intermediate.json", "05_cost_tradeoff.json")
