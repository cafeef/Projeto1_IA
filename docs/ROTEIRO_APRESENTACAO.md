# Roteiro da Apresentação — Agente de Combate à Dengue

Duração sugerida: 12–15 min de apresentação e 5 min de perguntas. Cada integrante fala
sobre sua parte, mas **todos** devem saber responder sobre os quatro algoritmos, a
heurística e os resultados.

## Antes de começar

- [ ] `uv sync` feito na máquina da apresentação; `uv run dengue` abre a janela.
- [ ] `uv run pytest` passando (mostrar se perguntarem sobre testes).
- [ ] `results/` com os gráficos da rodada final abertos em outra aba.
- [ ] Não jogar os cenários oficiais antes da demonstração, para não gerar partidas extras em
      `results/human_runs.jsonl`. Se precisar, use uma cópia do repositório.

## Sequência

| # | Tempo | Quem | Conteúdo |
|---|---|---|---|
| 1 | 1,5 min | Pessoa 4 | Problema: dengue, criadouros, objetivo do projeto e os dois participantes (usuário × agente). |
| 2 | 2,5 min | Pessoa 1 | Modelagem: grade → grafo implícito; estados, ações, `successors`, teste de objetivo, custos 1/2/4; formato JSON; os 3 cenários oficiais e por que o cenário 3 separa passos de custo. |
| 3 | 3 min | Pessoa 2 | Algoritmos: estrutura de cada fronteira (fila, pilha, heap), controle de visitados, onde é feito o teste de objetivo e por quê; heurística Manhattan × c_min, admissibilidade e consistência. |
| 4 | 3 min | Pessoa 3 | **Demonstração ao vivo** no cenário 3 (tecla 5): usuário anda pelo mapa, agente com BFS (custo 65), depois TAB → A\* (custo 21); mostrar explorados, caminho, painel final com a mensagem educativa. Mostrar o cenário sem rota (tecla 6 + X). |
| 5 | 3 min | Pessoa 4 | Resultados: Tabela 1 e gráficos de custo e de estados expandidos; respostas centrais (passos ≠ custo, a Gulosa enganada, o A\* ótimo, a DFS instável); comparação usuário × agente; conclusão e limitações. |

## Mensagens-chave

1. O mapa **não** vira um grafo explícito: os vizinhos são gerados sob demanda.
2. A BFS minimiza **passos**, e o A\* minimiza **custo**. No cenário 3 isso significa 17
   passos com custo 65, contra 21 passos com custo 21.
3. A heurística é admissível porque todo passo custa pelo menos `c_min` e são necessários
   pelo menos `manhattan` passos.
4. O tempo do algoritmo é medido **antes** da animação.
5. Usuário e agente usam o **mesmo** `GridProblem`, ou seja, a mesma instância.

## Perguntas prováveis (todos devem saber responder)

- Por que a BFS testa o objetivo na geração e o A\* na expansão?
- O que aconteceria com o A\* se a heurística superestimasse (por exemplo, Manhattan × 4)?
- Por que a Gulosa usa um `set` de visitados e o A\* usa `best_g`?
- Por que a DFS marca visitado na expansão e não na geração?
- Qual a diferença entre estado gerado e estado expandido? Como vocês contam cada um?
- Por que multiplicar a Manhattan pelo menor custo? E se a calçada custasse 2?
- A heurística é consistente? Qual a consequência prática disso?
- Por que a fronteira máxima é tão pequena nesses mapas?
- Como vocês garantem que o tempo não inclui a animação?
- Onde fica a regra que impede atravessar obstáculos? A interface decide algo?
- Por que o cenário intermediário tem 10×10 e não 12×12?
- Por que usar a primeira partida humana e não a melhor?
- Que biblioteca vocês usaram para a busca? (Nenhuma: só `deque`, `heapq`, `set`,
  `dict` e `list`.)
