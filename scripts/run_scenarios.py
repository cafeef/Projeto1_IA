"""Roda os 4 algoritmos em todos os cenários JSON e imprime um resumo.

Uso, a partir da raiz do repositório:
    python -m scripts.run_scenarios
ou:
    python scripts/run_scenarios.py

Não é um teste automatizado — é uma ferramenta de inspeção manual.
Serve para conferir que o pipeline funciona ponta a ponta com o
parser da Pessoa 1 e os cenários reais.
"""

import sys
from pathlib import Path

# Ajusta o path para permitir importar dengue_agent quando rodado
# como script standalone.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from dengue_agent.metrics import run_all
from dengue_agent.scenarios import load_scenario


SCENARIOS_DIR = ROOT / "scenarios"


def format_result(result) -> str:
    if not result.found:
        return f"  {result.algorithm:8s}  SEM SOLUÇÃO  (expandiu {result.expanded_states})"
    return (
        f"  {result.algorithm:8s}  "
        f"passos={result.steps:3d}  "
        f"custo={result.cost:4d}  "
        f"expandidos={result.expanded_states:5d}  "
        f"gerados={result.generated_states:5d}  "
        f"fronteira_max={result.max_frontier_size:4d}  "
        f"tempo={result.execution_time_ms:7.3f}ms"
    )


def main() -> None:
    json_files = sorted(SCENARIOS_DIR.glob("*.json"))
    if not json_files:
        print(f"Nenhum cenário encontrado em {SCENARIOS_DIR}")
        return

    for json_path in json_files:
        print(f"\n=== {json_path.name} ===")
        scenario = load_scenario(json_path)
        print(f"Nome: {scenario.name}")
        print(f"Grade: {scenario.rows}x{scenario.cols}  "
              f"Início: ({scenario.start.row},{scenario.start.col})  "
              f"Objetivo: ({scenario.goal.row},{scenario.goal.col})")
        for result in run_all(scenario):
            print(format_result(result))


if __name__ == "__main__":
    main()