# Plano de Trabalho - Agente de Combate a Dengue

Este plano foi elaborado a partir do enunciado do Projeto nº 1 da disciplina de Inteligencia Artificial. O PDF foi usado apenas como fonte de requisitos do trabalho academico; as instrucoes executadas no projeto sao as solicitadas pela equipe neste repositorio.

## 1. Objetivo do projeto

Desenvolver uma simulacao/jogo em Python no qual um usuario e um agente inteligente resolvem a mesma missao: sair de uma posicao inicial e alcancar um foco de dengue em uma grade bidimensional com obstaculos, terrenos e custos de deslocamento.

O sistema deve permitir comparar a decisao humana com algoritmos de busca implementados pela propria equipe:

- BFS, busca em largura.
- DFS, busca em profundidade.
- Busca Gulosa, usando `f(n) = h(n)`.
- A*, usando `f(n) = g(n) + h(n)`.

Nao devem ser usadas funcoes prontas de bibliotecas que implementem algoritmos de busca, heuristicas automaticas, pathfinding, A*, BFS, DFS, planners ou qualquer recurso equivalente aos conceitos estudados na disciplina. Bibliotecas externas podem ser usadas para interface, graficos, entrada, arquivos, testes e visualizacao, desde que a logica de IA seja autoral.

## 2. Requisitos extraidos do enunciado

### Entregas obrigatorias

- Codigo-fonte e executavel/forma de execucao.
- Relatorio tecnico detalhado.
- Demonstracao pratica presencial.
- Participacao de todos os membros, com capacidade individual de explicar a implementacao.

### Datas importantes

- Cadastro da equipe no arquivo compartilhado: ate 16/09/2026.
- Entrega no Moodle: ate 02/10/2026.
- Inicio das apresentacoes: 05/10/2026.

### Funcionalidades obrigatorias

- Representar o ambiente como matriz bidimensional.
- Definir posicao inicial, foco de dengue, celulas livres, obstaculos e ao menos dois terrenos com custos diferentes.
- Permitir movimentos em quatro direcoes: cima, baixo, esquerda e direita.
- Impedir movimento para fora da matriz ou atraves de obstaculos.
- Permitir controle manual do usuario.
- Executar o agente com BFS, DFS, Busca Gulosa ou A*.
- Usuario e agente devem resolver a mesma instancia: mesmo cenario, mesma origem e mesmo objetivo.
- Mostrar visualmente usuario, agente, foco, obstaculos, terrenos, estados explorados e caminhos.
- Manter a missao ativa ate usuario e agente chegarem ao foco.
- Ao final, exibir mensagem educativa sobre o foco encontrado.
- Registrar metricas do usuario e do agente.
- Criar pelo menos tres cenarios: simples, intermediario e complexo.
- Realizar 15 execucoes experimentais: 3 humanas e 12 algoritmicas.

### Metricas obrigatorias

Para o usuario:

- Caminho percorrido.
- Quantidade de passos.
- Custo total.
- Tempo ate alcancar o foco.

Para os algoritmos:

- Caminho encontrado.
- Quantidade de passos.
- Custo total.
- Estados expandidos.
- Estados gerados.
- Tempo de execucao do algoritmo, separado da animacao.
- Tamanho maximo da fronteira.

## 3. Stack proposta

### Implementacao principal obrigatoria

- Python 3.11+.
- Arcade para interface grafica 2D.
- Pytest para testes automatizados.
- Matplotlib ou Pandas apenas para gerar graficos/tabelas dos experimentos, sem uso em algoritmos de busca.
- JSON ou YAML para configuracao dos cenarios.

### Bônus educacional

- Godot 4 para uma versao jogavel educativa.
- A versao Godot deve reaproveitar os cenarios, resultados e regras do projeto principal.
- A logica dos algoritmos pode ser mantida em Python como referencia autoral, ou portada manualmente para GDScript, sem usar pathfinding pronto do Godot.

## 4. Arquitetura do projeto

Estrutura recomendada:

```text
Projeto1_IA/
  README.md
  docs/
    Projeto nº 1 - Agente de Combate a Dengue [04-09-26].pdf
    PLANO_DE_TRABALHO.md
    RELATORIO.md
  src/
    dengue_agent/
      __init__.py
      main.py
      config.py
      models.py
      grid.py
      scenarios.py
      education.py
      metrics.py
      experiments.py
      search/
        __init__.py
        common.py
        bfs.py
        dfs.py
        greedy.py
        astar.py
      ui/
        __init__.py
        app.py
        renderer.py
        controls.py
        panels.py
  assets/
    sprites/
    sounds/
    fonts/
  scenarios/
    simple.json
    intermediate.json
    complex.json
  tests/
    test_grid.py
    test_successors.py
    test_bfs.py
    test_dfs.py
    test_greedy.py
    test_astar.py
    test_metrics.py
  results/
    .gitkeep
  bonus_godot/
    project.godot
```

### Camadas

#### Dominio e modelagem

Responsavel por representar o problema de busca independentemente da interface.

Componentes:

- `Position`: coordenada `(row, col)`.
- `CellType`: livre, grama, dificil, obstaculo, foco.
- `TerrainCost`: tabela de custos positivos.
- `Scenario`: matriz, origem, foco, nome e mensagens educativas.
- `GridProblem`: estado inicial, teste de objetivo, sucessores e custo.

Regra principal: a interface Arcade nunca deve conter a logica dos algoritmos. Ela apenas desenha o estado atual e envia comandos de entrada.

#### Algoritmos de busca

Cada algoritmo deve ter uma funcao propria, implementada manualmente:

- `breadth_first_search(problem)`.
- `depth_first_search(problem)`.
- `greedy_search(problem, heuristic)`.
- `astar_search(problem, heuristic)`.

Todos devem retornar uma estrutura padronizada:

```python
SearchResult(
    algorithm: str,
    path: list[Position],
    cost: int,
    steps: int,
    expanded_states: int,
    generated_states: int,
    max_frontier_size: int,
    execution_time_ms: float,
    explored_order: list[Position],
    found: bool,
)
```

Heuristica recomendada:

```text
h(n) = distancia_manhattan(n, objetivo) * menor_custo_de_movimento
```

Justificativa: em uma grade com movimentos ortogonais, a Distancia Manhattan estima a menor quantidade de movimentos ate o objetivo sem considerar obstaculos. Multiplicar pelo menor custo positivo preserva uma estimativa que nao ultrapassa o custo real minimo, desde que todos os custos de terreno sejam pelo menos esse valor. Isso torna a heuristica admissivel para A* na modelagem proposta.

#### Interface Arcade

Telas recomendadas:

- Menu inicial: selecao de cenario e algoritmo.
- Simulacao: grade, usuario, agente, foco, terrenos, obstaculos, explorados e caminho.
- Resultado: tabela comparando usuario e agente selecionado.
- Tela de experimentos: execucao automatica dos quatro algoritmos no cenario selecionado.

Controles:

- Setas ou WASD para mover o usuario.
- Botao/tecla para iniciar missao.
- Seletor de algoritmo: BFS, DFS, Gulosa, A*.
- Reset de missao.

#### Experimentos e relatorio

O modulo `experiments.py` deve executar todos os algoritmos nos tres cenarios, gerar um arquivo CSV/JSON em `results/` e facilitar a criacao de tabelas/graficos para o relatorio.

Campos minimos:

- Cenario.
- Metodo.
- Passos.
- Custo.
- Tempo.
- Estados expandidos.
- Estados gerados.
- Tamanho maximo da fronteira.
- Caminho.

## 5. Modelagem dos cenarios

> Implementado: os cenarios oficiais sao `scenarios/01_simple.json` (8x8),
> `02_intermediate.json` (10x10) e `05_cost_tradeoff.json` (15x20), listados em
> `OFFICIAL_SCENARIOS` (`config.py`). O intermediario ficou 10x10 em vez de 12x12, o que foi
> suficiente para ter becos e rotas alternativas (justificado no relatorio, Secao 7.1). Os
> mapas `03_advanced`, `04_expert` e `06_impossible` sao extras, fora das 15 execucoes.

### Cenario 1 - Simples

- Grade pequena, por exemplo 8x8.
- Poucos obstaculos.
- Custos quase uniformes.
- Serve para validar o funcionamento visual e comparar caminhos basicos.

### Cenario 2 - Intermediario

- Grade media, por exemplo 12x12.
- Mais obstaculos.
- Dois ou tres caminhos viaveis.
- Terrenos com custos diferentes em regioes estrategicas.

### Cenario 3 - Complexo

- Grade maior, por exemplo 16x16 ou 20x20.
- Multiplos caminhos.
- Obstaculos formando desvios.
- Terrenos de alto custo criando o caso obrigatorio: menor caminho em passos nao deve ser necessariamente o menor caminho em custo.

## 6. Divisao individual para 4 pessoas

### Pessoa 1 - Modelagem, cenarios e estrutura do dominio

Responsabilidades:

- Criar a estrutura inicial do projeto Python.
- Definir classes/modelos principais: posicao, celula, terreno, cenario e problema de busca.
- Implementar carregamento dos cenarios em JSON/YAML.
- Criar os tres cenarios obrigatorios.
- Garantir que o cenario complexo tenha diferenca clara entre menor caminho em passos e menor caminho em custo.
- Implementar `successors`, validacao de movimentos e calculo de custo.
- Escrever testes de grade, sucessores, obstaculos e custos.

Entregaveis:

- `models.py`, `grid.py`, `scenarios.py`.
- `scenarios/simple.json`, `intermediate.json`, `complex.json`.
- Testes de modelagem.
- Texto inicial da secao "Modelagem do Problema" do relatorio.

### Pessoa 2 - Algoritmos de busca e metricas

Responsabilidades:

- Implementar BFS manualmente.
- Implementar DFS manualmente.
- Implementar Busca Gulosa manualmente.
- Implementar A* manualmente.
- Criar estrutura comum `SearchResult`.
- Medir tempo de execucao sem incluir animacao.
- Contabilizar estados expandidos, estados gerados e tamanho maximo da fronteira.
- Implementar reconstrucao de caminho.
- Implementar heuristica Manhattan ponderada pelo menor custo.
- Escrever testes unitarios para todos os algoritmos.

Entregaveis:

- `search/common.py`, `bfs.py`, `dfs.py`, `greedy.py`, `astar.py`.
- `metrics.py`.
- Testes dos quatro algoritmos.
- Texto inicial das secoes "Implementacao dos Algoritmos" e "Heuristica Utilizada" do relatorio.

Restricao importante:

- Nao usar funcoes prontas de pathfinding, grafos, IA ou bibliotecas como NetworkX para resolver a busca. Estruturas permitidas da biblioteca padrao incluem `deque`, `list`, `dict`, `set` e `heapq`, desde que a logica do algoritmo seja implementada pela equipe.

### Pessoa 3 - Interface Arcade e interacao do usuario

Responsabilidades:

- Criar a janela principal com Arcade.
- Renderizar matriz, terrenos, obstaculos, foco, usuario e agente.
- Implementar controle manual do usuario.
- Impedir movimentos invalidos.
- Registrar caminho, passos, custo e tempo do usuario.
- Criar selecao de cenario e algoritmo.
- Animar o agente percorrendo o caminho retornado pelo algoritmo.
- Mostrar estados explorados e caminho final.
- Exibir resultado comparativo ao final da missao.
- Integrar mensagens educativas ao alcancar o foco.

Entregaveis:

- `ui/app.py`, `renderer.py`, `controls.py`, `panels.py`.
- `main.py`.
- Assets visuais simples em `assets/`.
- Texto inicial da secao "Desenvolvimento e Funcionamento do Ambiente" e "Conteudo Educacional".

### Pessoa 4 - Experimentos, relatorio, qualidade e bonus Godot

Responsabilidades:

- Criar script de experimentos obrigatorios.
- Gerar tabelas e graficos para os tres cenarios.
- Organizar `results/`.
- Coordenar o relatorio tecnico completo.
- Verificar se todas as perguntas obrigatorias da analise foram respondidas.
- Revisar clareza, ABNT/referencias e organizacao textual.
- Preparar roteiro da apresentacao oral.
- Liderar o prototipo bonus em Godot.

Entregaveis:

- `experiments.py`.
- Arquivos de resultados em `results/`.
- `docs/RELATORIO.md` ou documento equivalente.
- Graficos/tabelas.
- Roteiro de apresentacao.
- Pasta `bonus_godot/` com prototipo jogavel, caso a equipe avance no bonus.

Observacao: apesar dessa divisao, todos devem estudar os quatro algoritmos e a arquitetura geral, porque a apresentacao tera perguntas individuais.

## 7. Sequencia de tarefas recomendada

### Fase 0 - Organizacao inicial

Prazo sugerido: 14/09 a 16/09.

- Confirmar os 4 integrantes.
- Cadastrar a equipe ate 16/09/2026.
- Criar issues no GitHub para cada tarefa deste plano.
- Definir convencoes: branch por pessoa, pull request obrigatorio e revisao por pelo menos uma pessoa.
- Criar ambiente Python e dependencias iniciais.

### Fase 1 - Nucleo do problema

Prazo sugerido: 17/09 a 20/09.

- Implementar modelos, grade, cenarios e sucessores.
- Criar cenarios simples em JSON/YAML.
- Implementar testes da modelagem.
- Validar manualmente que origem, foco, obstaculos e custos funcionam.

Marco de conclusao: os cenarios carregam e o problema retorna sucessores validos com custos corretos.

### Fase 2 - Algoritmos

Prazo sugerido: 20/09 a 23/09.

- Implementar BFS e DFS.
- Implementar Gulosa e A*.
- Implementar heuristica.
- Padronizar retorno de metricas.
- Testar algoritmos em grades pequenas com resposta conhecida.

Marco de conclusao: todos os algoritmos encontram solucao nos tres cenarios e retornam metricas.

### Fase 3 - Interface Arcade

Prazo sugerido: 22/09 a 26/09.

- Criar janela e renderizacao da grade.
- Implementar movimento manual.
- Integrar selecao de cenario e algoritmo.
- Integrar execucao do agente.
- Exibir estados explorados, caminho e metricas.
- Exibir mensagem educativa final.

Marco de conclusao: uma missao completa pode ser jogada e comparada com um algoritmo selecionado.

### Fase 4 - Experimentos e analise

Prazo sugerido: 26/09 a 29/09.

- Executar 3 execucoes humanas, uma por cenario.
- Executar BFS, DFS, Gulosa e A* nos tres cenarios.
- Gerar tabelas e graficos.
- Responder as 15 perguntas obrigatorias da analise comparativa.

Marco de conclusao: `results/` contem dados suficientes para preencher o relatorio.

### Fase 5 - Relatorio e apresentacao

Prazo sugerido: 29/09 a 01/10.

- Finalizar relatorio tecnico.
- Revisar aderencia aos criterios de avaliacao.
- Conferir se codigo e relatorio estao no pacote final.
- Ensaiar apresentacao com perguntas individuais.

Marco de conclusao: equipe consegue demonstrar o sistema e explicar modelagem, heuristica, algoritmos e resultados.

### Fase 6 - Bonus Godot

Prazo sugerido: paralelo, somente depois que o nucleo Python estiver estavel.

- Criar versao educativa com fases, missao visual e interacao simplificada.
- Usar sprites maiores, textos curtos, feedback sonoro/visual e instrucoes claras.
- Reaproveitar os tres cenarios.
- Nao usar pathfinding pronto do Godot.
- Priorizar funcionalidade sem erros, pois o bonus depende da implementacao basica estar correta.

## 8. Backlog de issues sugeridas

- `setup`: criar estrutura Python, ambiente virtual e dependencias.
- `domain`: implementar tipos de celula, posicao, custos e cenario.
- `grid`: implementar movimentos validos, sucessores e custo.
- `scenarios`: criar tres cenarios obrigatorios.
- `search-bfs`: implementar BFS autoral.
- `search-dfs`: implementar DFS autoral.
- `search-greedy`: implementar Busca Gulosa autoral.
- `search-astar`: implementar A* autoral.
- `heuristic`: implementar e documentar Manhattan ponderada.
- `metrics`: padronizar metricas de usuario e agente.
- `ui-grid`: renderizar grade no Arcade.
- `ui-player`: implementar movimento manual.
- `ui-agent`: animar agente e explorados.
- `ui-results`: tela final de comparacao.
- `education`: mensagens educativas por foco.
- `experiments`: executar algoritmos e exportar resultados.
- `report`: escrever relatorio tecnico.
- `presentation`: preparar roteiro e perguntas individuais.
- `bonus-godot`: prototipo educativo em Godot.

## 9. Regras de colaboracao no GitHub

- `main` deve conter apenas versoes estaveis.
- Cada pessoa trabalha em uma branch propria:
  - `feature/domain-scenarios`
  - `feature/search-algorithms`
  - `feature/arcade-ui`
  - `feature/experiments-report-godot`
- Toda tarefa deve virar issue.
- Todo merge deve passar por pull request.
- Pull requests devem informar:
  - O que foi feito.
  - Como testar.
  - Quais arquivos principais foram alterados.
  - Se ha impacto no relatorio.
- Antes da entrega, criar uma tag:
  - `v1.0-entrega`

## 10. Checklist de conformidade com a avaliacao

- [x] Modelagem correta do ambiente.
- [x] Usuario funcionando.
- [x] Usuario e agente atuando na mesma missao.
- [x] BFS implementada manualmente.
- [x] DFS implementada manualmente.
- [x] Busca Gulosa implementada manualmente.
- [x] A* implementado manualmente.
- [x] Heuristica definida, justificada e discutida.
- [x] Conteudo educacional apresentado.
- [x] Tres cenarios implementados.
- [x] Resultados gerados para 15 execucoes.
- [x] Tabelas e graficos no relatorio.
- [x] Analise comparativa responde as perguntas obrigatorias.
- [x] Codigo organizado.
- [ ] Todos os membros conseguem explicar sua parte e a visao geral.
- [ ] Bonus Godot nao compromete a implementacao principal.

