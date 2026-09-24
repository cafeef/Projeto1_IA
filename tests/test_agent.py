from pathlib import Path

from dengue_agent.agent import EXPLORE_STEP_S, MOVE_STEP_S, AgentRun
from dengue_agent.grid import GridProblem
from dengue_agent.scenarios import load_scenario
from dengue_agent.search.astar import astar_search


MAPS = Path(__file__).parents[1] / "scenarios"


def rodar(nome: str) -> tuple[AgentRun, GridProblem]:
    problem = GridProblem(load_scenario(MAPS / nome))
    return AgentRun(astar_search(problem), problem.initial_state), problem


def test_explora_antes_de_andar() -> None:
    agent, problem = rodar("01_simple.json")
    agent.update(EXPLORE_STEP_S * 3.5)  # meio passo de folga contra arredondamento
    assert agent.exploring
    assert agent.explored_shown == 3
    assert agent.position == problem.initial_state


def test_termina_no_foco() -> None:
    agent, problem = rodar("01_simple.json")
    result = agent.result
    total = EXPLORE_STEP_S * len(result.explored_order) + MOVE_STEP_S * result.steps
    agent.update(total + 1)
    assert agent.finished
    assert agent.position == problem.goal_state


def test_sem_rota_fica_no_inicio() -> None:
    agent, problem = rodar("06_impossible.json")
    assert not agent.result.found
    agent.update(EXPLORE_STEP_S * len(agent.result.explored_order) + 1)
    assert agent.finished
    assert agent.explored_shown == len(agent.result.explored_order)
    assert agent.position == problem.initial_state
