# Projeto1_IA
Repositório referente ao código desenvolvido para o Projeto 1 da disciplina de Inteligência Artificial.

## Planejamento

O plano de trabalho, arquitetura proposta, divisão para 4 integrantes e sequência de tarefas estão em:

- [docs/PLANO_DE_TRABALHO.md](docs/PLANO_DE_TRABALHO.md)


## Desenvolvimento

O projeto usa Python 3.11+ e [uv](https://docs.astral.sh/uv/).

```bash
uv sync
uv run pytest
```

Os cenários ficam em `scenarios/`. O domínio em `src/dengue_agent/` não depende da interface gráfica: buscas e interface devem consumir `Scenario` e `GridProblem`.
