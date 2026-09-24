"""Caminhos compartilhados da aplicação."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = PROJECT_ROOT / "scenarios"
RESULTS_DIR = PROJECT_ROOT / "results"
HUMAN_RUNS_FILE = RESULTS_DIR / "human_runs.jsonl"  # uma linha JSON por partida
