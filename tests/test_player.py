import json
from pathlib import Path

from dengue_agent.grid import GridProblem
from dengue_agent.models import Position
from dengue_agent.player import Player
from dengue_agent.scenarios import load_scenario


MAPS = Path(__file__).parents[1] / "scenarios"

UP, RIGHT, DOWN, LEFT = (-1, 0), (0, 1), (1, 0), (0, -1)


def novo_jogador() -> Player:
    return Player(GridProblem(load_scenario(MAPS / "01_simple.json")))


def test_movimento_invalido_nao_conta() -> None:
    player = novo_jogador()
    assert not player.move(*UP)  # borda de obstáculos
    assert not player.move(*LEFT)
    assert player.position == Position(1, 1)
    assert player.steps == 0 and player.cost == 0
    assert player.elapsed_s == 0.0


def test_custo_do_terreno_de_destino() -> None:
    player = novo_jogador()
    for _ in range(3):
        assert player.move(*RIGHT)
    # (1,2) e (1,3) livres, (1,4) grama.
    assert player.position == Position(1, 4)
    assert player.steps == 3
    assert player.cost == 1 + 1 + 2


def test_chega_ao_foco_e_trava() -> None:
    player = novo_jogador()
    route = [RIGHT] * 5 + [DOWN] * 4
    for move in route:
        assert player.move(*move)

    assert player.position == Position(5, 6)
    assert player.finished
    assert player.steps == 9
    assert player.cost == sum(player.problem.cost(p) for p in player.path[1:])

    tempo = player.elapsed_s
    assert not player.move(*UP)  # missão encerrada
    assert player.steps == 9
    assert player.elapsed_s == tempo


def test_desistir_encerra_sem_chegar() -> None:
    player = novo_jogador()
    player.move(*RIGHT)
    player.give_up()
    assert player.done and player.gave_up
    assert not player.finished

    tempo = player.elapsed_s
    assert not player.move(*RIGHT)
    assert player.steps == 1
    assert player.elapsed_s == tempo


def test_salva_partidas_em_json_lines(tmp_path: Path) -> None:
    arquivo = tmp_path / "results" / "human_runs.jsonl"

    player = novo_jogador()
    for move in [RIGHT] * 5 + [DOWN] * 4:
        player.move(*move)
    player.save(arquivo, "Quintal simples")

    desistente = novo_jogador()
    desistente.give_up()
    desistente.save(arquivo, "Quintal simples")

    linhas = [json.loads(l) for l in arquivo.read_text(encoding="utf-8").splitlines()]
    assert len(linhas) == 2
    primeira = linhas[0]
    assert primeira["method"] == "Usuário"
    assert primeira["found"] and not primeira["gave_up"]
    assert (primeira["steps"], primeira["cost"]) == (9, player.cost)
    assert primeira["path"][0] == [1, 1] and primeira["path"][-1] == [5, 6]
    assert linhas[1]["gave_up"] and not linhas[1]["found"]
