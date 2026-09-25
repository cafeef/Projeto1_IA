# Projeto1_IA
Repositório referente ao código desenvolvido para o Projeto 1 da disciplina de Inteligência Artificial.

## Planejamento e documentos

- [docs/PLANO_DE_TRABALHO.md](docs/PLANO_DE_TRABALHO.md) — plano, arquitetura e divisão de tarefas.
- [docs/RELATORIO.md](docs/RELATORIO.md) — relatório técnico (seções 1 a 10 do Apêndice A).
- [docs/ROTEIRO_APRESENTACAO.md](docs/ROTEIRO_APRESENTACAO.md) — roteiro e perguntas da defesa.
- [docs/PROJETO.md](docs/PROJETO.md) — enunciado.

## Desenvolvimento

O projeto usa Python 3.11+ e [uv](https://docs.astral.sh/uv/).

```bash
uv sync
uv run pytest
```

### Sem uv (venv + pip)

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -e . matplotlib pytest
```

Depois disso, os comandos `uv run X` viram só `X`: `pytest`, `dengue` e `dengue-experimentos`. Também funcionam `python -m dengue_agent.main` e `python -m dengue_agent.experiments`.

Os cenários ficam em `scenarios/`. O domínio em `src/dengue_agent/` não depende da interface gráfica: buscas e interface devem consumir `Scenario` e `GridProblem`.

## Jogo

```bash
uv run dengue
```

| Tecla | Ação |
|---|---|
| Setas / WASD | move o usuário |
| ESPAÇO | inicia o agente |
| TAB | troca o algoritmo (BFS, DFS, Gulosa, A*) |
| 1–6 | troca o cenário |
| R | reinicia a missão |
| X | desiste (cenário sem rota) |

Cada partida do usuário é gravada em `results/human_runs.jsonl`.

## Experimentos

Os cenários oficiais são `01_simple`, `02_intermediate` e `05_cost_tradeoff` (`OFFICIAL_SCENARIOS` em `config.py`).

1. Apague `results/human_runs.jsonl`, se houver partidas de teste.
2. Jogue **uma vez** cada cenário oficial (teclas 1, 2 e 5) em `uv run dengue`.
3. Rode:

```bash
uv run dengue-experimentos
```

O script gera em `results/`: `experimentos.csv`, `experimentos.json`, `tabela_experimentos.md`, os gráficos `grafico_*.png` e os mapas de caminhos `caminhos_cenario*.png`. Para inspecionar todos os seis mapas no terminal, use `uv run python scripts/run_scenarios.py`.
