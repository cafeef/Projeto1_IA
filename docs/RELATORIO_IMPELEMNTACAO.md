# Seções do relatório implementação (rascunho)

## 4. Implementação dos Algoritmos

Foram implementados manualmente os quatro algoritmos de busca exigidos:
Busca em Largura (BFS), Busca em Profundidade (DFS), Busca Gulosa e A\*.
Todos operam sobre o mesmo `GridProblem`, que expõe o estado inicial, o
teste de objetivo e a função sucessora `successors(position)`. Nenhuma
biblioteca externa de busca, grafos ou pathfinding foi utilizada; as
únicas estruturas da biblioteca padrão empregadas são `collections.deque`,
`heapq`, `set`, `dict` e `list`, todas usadas como containers genéricos.

Todos os algoritmos compartilham três componentes definidos em
`search/common.py`:

- **`Node`**: encapsula uma posição, seu nó-pai, o custo acumulado do
  caminho `g(n)` e a profundidade. A referência ao pai permite reconstruir
  o caminho final subindo pela cadeia até o nó inicial.
- **`SearchResult`**: estrutura de retorno padronizada contendo caminho,
  custo, número de passos, estados expandidos, estados gerados, tamanho
  máximo da fronteira, tempo de execução e a lista `explored_order` com
  a sequência de posições expandidas (usada pela interface para animar
  a exploração).
- **`reconstruct_path(node)`**: percorre a cadeia de pais e devolve o
  caminho em ordem do início ao objetivo.

O tempo de execução é medido com `time.perf_counter()`, contador
monotônico de alta resolução, e refere-se **apenas ao algoritmo**, sem
incluir a animação visual, conforme exigido pelo enunciado.

### 4.1 Busca em Largura (BFS)

A BFS utiliza uma fila FIFO (`collections.deque`) como fronteira. A cada
iteração, o nó mais antigo é retirado e seus sucessores válidos são
gerados. Um conjunto `reached` guarda todas as posições já alcançadas
(inseridas na fronteira ou expandidas), evitando revisita. O teste de
objetivo é feito **na geração**, ou seja, assim que um filho é criado
verifica-se se ele é o objetivo. Essa otimização é válida especificamente
para BFS: como a busca é feita por níveis, o primeiro nó-filho que atinge
o objetivo tem, necessariamente, o menor número de passos. Sob esta
formulação, BFS é ótimo em número de passos, mas não em custo quando os
terrenos têm pesos distintos.

### 4.2 Busca em Profundidade (DFS)

A DFS utiliza uma pilha LIFO (uma `list` com `append`/`pop`) como
fronteira. A cada iteração, o nó mais recente é retirado e expandido.
Diferentemente da BFS, o conjunto `visited` é atualizado **na expansão**,
não na geração. Essa escolha preserva o comportamento característico da
DFS: um mesmo estado pode aparecer na pilha por caminhos diferentes, e
apenas o primeiro caminho a expandi-lo o marca como visitado; os demais
são descartados no início da iteração. Sem controle de visitados, a DFS
poderia entrar em ciclo em uma grade com múltiplos caminhos.

A ordem em que os sucessores são gerados é fixa e definida em
`grid.py` como Norte, Leste, Sul, Oeste. Como a pilha é LIFO, o último
sucessor gerado (Oeste) é o primeiro a ser expandido. Essa ordem
determinística garante reprodutibilidade durante a demonstração. A DFS
**não** garante o menor caminho em passos nem o de menor custo — o
caminho encontrado depende diretamente da ordem de expansão.

### 4.3 Busca Gulosa

A Busca Gulosa utiliza uma fila de prioridade (`heapq`) ordenada por
`f(n) = h(n)`, onde `h(n)` é a heurística Manhattan ponderada pelo menor
custo de terreno (detalhada na Seção 5). Cada entrada no heap é uma
tripla `(h, contador, Node)`, em que o contador incremental serve como
critério de desempate: quando dois nós têm o mesmo `h`, o inserido
primeiro é retirado primeiro (FIFO). O contador também impede que o
`heapq` tente comparar `Node`s entre si, o que levantaria `TypeError`.

O conjunto `reached` é atualizado na geração, análogo à BFS. Isso é
suficiente para a Gulosa porque `h` depende apenas da posição: dois
caminhos distintos até a mesma célula têm o mesmo `h`, e a Gulosa não
considera `g` para decidir qual expandir. A Gulosa **não é ótima**:
ela pode escolher caminhos com custo elevado se a heurística "puxar"
para uma região próxima ao objetivo mas cercada por terreno caro ou
obstáculos.

### 4.4 A\*

O A\* utiliza uma fila de prioridade ordenada por `f(n) = g(n) + h(n)`.
A estrutura do heap é idêntica à da Gulosa: tripla `(f, contador, Node)`,
com desempate por contador. Duas diferenças estruturais em relação à
Gulosa:

1. **Controle de estados via `best_g`**: em vez de um simples `set`, o
   A\* mantém um dicionário `best_g[position] = menor_g_conhecido`.
   Um sucessor só é inserido na fronteira se seu novo `g` for estritamente
   menor que o melhor `g` conhecido para aquela posição. Isso é o que
   caracteriza o *graph search* do A\*.
2. **Descarte de nós obsoletos**: como `heapq` não suporta remoção no
   meio, quando um nó é retirado do heap verifica-se se seu `path_cost`
   ainda é o melhor conhecido para sua posição; caso contrário, é
   descartado silenciosamente.

O teste de objetivo é feito **na expansão**, não na geração. Essa
distinção é crítica para a otimalidade: um nó pode ser *gerado* por um
caminho subótimo antes de ser *gerado novamente* por um caminho ótimo.
Apenas quando o nó é retirado do topo do heap — com o menor `f` — temos
garantia de que aquele é o melhor caminho até ele. Sob heurística
admissível e teste na expansão, A\* encontra sempre a solução de menor
custo.

## 5. Heurística Utilizada

Para os algoritmos informados (Busca Gulosa e A\*) foi implementada a
heurística **Distância Manhattan ponderada pelo menor custo de terreno**:

h(n) = ( |row(n) - row(goal)| + |col(n) - col(goal)| ) * c_min


onde `c_min` é o menor custo entre os terrenos transitáveis do ambiente.
Na configuração base — `FREE = 1`, `GRASS = 2`, `DIFFICULT = 4` —
temos `c_min = 1`, e a fórmula se reduz à Distância Manhattan pura.
Multiplicar por `c_min` mantém a heurística escalável caso a equipe
altere os custos base sem invalidar sua correção teórica.

### 5.1 Justificativa

A escolha se justifica por três motivos:

1. **Compatível com o espaço de ações.** O agente só se move em quatro
   direções ortogonais (Norte, Sul, Leste, Oeste). A Distância Manhattan
   é, por construção, o número mínimo de passos ortogonais entre dois
   pontos em uma grade sem obstáculos.
2. **Barata de calcular.** Duas subtrações, dois valores absolutos e uma
   multiplicação — `O(1)`. A heurística é chamada uma vez por sucessor
   gerado.
3. **Sensível a diferentes custos de terreno.** Ao multiplicar pelo
   menor custo possível, a estimativa é ajustada para a escala real dos
   custos do ambiente, permanecendo admissível mesmo quando existem
   terrenos com custos elevados.

### 5.2 Admissibilidade

Uma heurística é admissível se, para todo estado `n`, `h(n)` **nunca
superestima** o custo real do menor caminho de `n` até o objetivo.

Prova para o problema modelado:

- Todo caminho de `n` até o objetivo tem, no mínimo,
  `manhattan(n, goal)` passos, pois cada movimento altera a linha ou a
  coluna em exatamente uma unidade.
- Todo passo custa, no mínimo, `c_min` (pois `c_min` é o menor custo
  entre os terrenos transitáveis).
- Portanto, o custo real do menor caminho é ao menos
  `manhattan(n, goal) * c_min`, que é exatamente `h(n)`.

Logo, `h(n) <= custo_real(n, goal)` para todo `n`, e a heurística é
**admissível**. Isso garante que A\* encontra sempre a solução ótima
neste problema.

### 5.3 Consistência

Uma heurística é consistente (ou monotônica) se, para todo nó `n` e todo
sucessor `n'`,

h(n) <= custo(n, n') + h(n')


Prova:

- Como `n` e `n'` são vizinhos ortogonais, `manhattan(n, goal)` e
  `manhattan(n', goal)` diferem em exatamente 1. Consequentemente,
  `h(n) - h(n')` pertence ao conjunto `{-c_min, +c_min}`.
- O custo do passo de `n` para `n'` é o custo da célula `n'`, que é no
  mínimo `c_min`.
- No pior caso (`h(n) - h(n') = +c_min`), temos
  `h(n) = c_min + h(n') <= custo(n, n') + h(n')`, satisfazendo a
  desigualdade.

A heurística é, portanto, **consistente**. Consistência implica
admissibilidade e traz uma consequência prática importante: a primeira
vez que A\* expande um nó, ele já o faz com o menor `g` possível. Isso
significa que, para este problema, A\* não precisa reabrir nós já
fechados. Na implementação, o mecanismo de descarte de nós obsoletos
(via `best_g`) foi mantido por robustez, mas na prática raramente é
acionado.

# Insumo para a Seção 8 (Análise dos Resultados) — da Pessoa 2

Este arquivo é rascunho baseado nas execuções reais dos quatro algoritmos
nos cenários do repositório. Uso livre pela Pessoa 4 para consolidar a
Seção 8 do relatório. Números concretos abaixo — se algum cenário for
regenerado ou substituído, refazer a coleta com `python scripts/run_scenarios.py`.

## Dados observados (execução em 21/09/2026)

Considerando os três cenários oficiais (01_simple, 02_intermediate,
05_cost_tradeoff):

| Cenário | Método | Passos | Custo | Expandidos | Gerados | Fronteira máx | Tempo (ms) |
|---|---|---|---|---|---|---|---|
| 01_simple | BFS | 9 | 10 | 20 | 23 | 3 | 0.57 |
| 01_simple | DFS | 11 | 15 | 15 | 17 | 4 | 0.22 |
| 01_simple | Gulosa | 9 | 10 | 10 | 13 | 4 | 0.17 |
| 01_simple | A\* | 9 | 10 | 16 | 17 | 3 | 0.29 |
| 02_intermediate | BFS | 14 | 14 | 39 | 41 | 5 | 0.76 |
| 02_intermediate | DFS | 16 | 19 | 18 | 22 | 5 | 0.25 |
| 02_intermediate | Gulosa | 14 | 14 | 15 | 20 | 6 | 0.23 |
| 02_intermediate | A\* | 14 | 14 | 20 | 26 | 7 | 0.33 |
| 05_cost_tradeoff | BFS | 17 | 65 | 77 | 84 | 7 | 1.21 |
| 05_cost_tradeoff | DFS | 41 | 41 | 122 | 128 | 8 | 3.03 |
| 05_cost_tradeoff | Gulosa | 17 | 65 | 18 | 19 | 2 | 0.49 |
| 05_cost_tradeoff | A\* | 21 | 21 | 23 | 26 | 4 | 0.88 |

## Respostas às 15 perguntas obrigatórias

**1. Todos os algoritmos encontraram solução em todos os cenários?**
Sim, nos três cenários oficiais. Testes adicionais no cenário
06_impossible confirmam que os quatro algoritmos também terminam
corretamente reportando falha quando o objetivo é inalcançável.

**2. Qual algoritmo expandiu mais estados?**
Depende do cenário. Em 01_simple e 02_intermediate, BFS expandiu mais.
Em 05_cost_tradeoff, DFS expandiu mais (122 estados), refletindo sua
tendência de percorrer caminhos longos antes de retroceder.

**3. Qual algoritmo apresentou maior tamanho de fronteira?**
Em 01_simple, DFS e Gulosa empataram com 4. Em 02_intermediate, A\*
teve 7. Em 05_cost_tradeoff, DFS teve 8. Não há um "vencedor" único —
o tamanho da fronteira depende da topologia do cenário e da estratégia
do algoritmo. Vale notar que a fronteira máxima permaneceu pequena em
todos os casos (≤ 8), o que é esperado numa grade sem grande fator de
ramificação (no máximo 4 vizinhos).

**4. A DFS apresentou algum comportamento desfavorável?**
Sim, e de forma acentuada. Em 01_simple, DFS achou caminho de 11 passos
(custo 15) enquanto o ótimo é 9 passos (custo 10). Em 05_cost_tradeoff,
DFS achou caminho de 41 passos (custo 41) — quase o dobro do que A\*
achou (21 passos, custo 21). Também foi o algoritmo mais lento nesse
cenário (3.03 ms). O comportamento é esperado: DFS aprofunda antes de
avaliar alternativas, e em grids grandes isso a leva a caminhos longos
antes de encontrar o objetivo.

**5. BFS encontrou o caminho com menor quantidade de passos?**
Sim, em todos os cenários. Em 01_simple e 02_intermediate empatou com
Gulosa e A\* (todos com 9 e 14 passos respectivamente). Em
05_cost_tradeoff, BFS achou 17 passos — o mínimo em número de passos.

**6. O caminho com menos passos foi sempre o caminho de menor custo?**
Não. Este é o achado mais importante da análise. Em 05_cost_tradeoff,
BFS achou o caminho de 17 passos, mas com custo 65 — atravessando
terreno de custo elevado. A\* achou um caminho de 21 passos (mais
longo), mas com custo 21 — desviando do terreno caro. A diferença de
custo é de mais de 3× a favor do caminho mais longo. Esse cenário
demonstra concretamente por que algoritmos sensíveis a custo (como A\*)
são necessários em problemas com terrenos heterogêneos.

**7. A Busca Gulosa encontrou a solução de menor custo?**
Não em 05_cost_tradeoff (custo 65 vs 21 do A\*). Empatou com A\* em
01_simple e 02_intermediate porque nesses cenários o caminho ótimo em
passos coincide com o ótimo em custo. A Gulosa ignora `g(n)` e decide
apenas pela heurística — quando a heurística "aponta" para uma
direção que depois se revela cara, ela não corrige o rumo.

**8. A\* encontrou a solução de menor custo?**
Sim, em todos os cenários. É o único algoritmo com essa garantia entre
os quatro implementados, sob heurística admissível (comprovada na
Seção 5 do relatório).

**9. A heurística influenciou o desempenho?**
Sim, mas de forma variável conforme o cenário:
- Em 01_simple, Gulosa expandiu apenas 10 estados (metade do BFS).
- Em 02_intermediate, Gulosa expandiu 15 estados (BFS expandiu 39).
- Em 05_cost_tradeoff, o contraste é máximo: Gulosa expandiu apenas 18
  estados, enquanto BFS expandiu 77 — redução de mais de 4×.
A heurística reduz sistematicamente a exploração quando aponta na
direção correta. O custo dessa redução é aparente na Gulosa (que troca
qualidade por velocidade); no A\*, a heurística acelera sem sacrificar
otimalidade.

**10. Qual algoritmo apresentou melhor desempenho nos cenários mais complexos?**
Depende do critério:
- Menor custo → A\*
- Menor tempo → Gulosa
- Menor estados expandidos → Gulosa
- Menor memória (fronteira) → Gulosa
A\* é o melhor equilibrado: paga um pouco mais em tempo e memória para
garantir custo ótimo. Em 05_cost_tradeoff, A\* expandiu 23 estados vs
77 do BFS, mostrando que a heurística vale a pena mesmo quando exige
computação adicional.

**11. O usuário conseguiu obter menor custo que algum dos algoritmos?**
[A responder após execuções humanas — Pessoa 4]

**12. Usuário e agente escolheram caminhos diferentes?**
[A responder após execuções humanas]

**13. Em quais situações o agente superou claramente o usuário?**
[A responder após execuções humanas. Expectativa: em cenários com
trade-off passos vs custo (como 05_cost_tradeoff), o usuário provavelmente
tenderá ao caminho visualmente "mais curto" e não perceberá o trade-off
de custo, enquanto o A\* sempre escolherá o ótimo.]

**14. Em quais situações o usuário apresentou desempenho semelhante ou superior?**
[A responder após execuções humanas. Expectativa: em 01_simple, com
poucos obstáculos e custos uniformes, o usuário pode empatar com BFS
em passos e custo.]

**15. Qual algoritmo seria mais adequado para esse problema?**
A\*. É o único que combina completude, otimalidade em custo e uso da
heurística para reduzir a exploração. A Gulosa é mais rápida mas não
garante qualidade da solução. BFS garante menor número de passos mas
ignora custos — o que é problemático no domínio da dengue, onde
terrenos diferentes representam obstáculos parciais reais (grama alta,
terreno de difícil acesso). DFS não tem garantia útil neste domínio.

## Observações adicionais para o relatório

- O cenário 05 é o mais informativo: é o único que separa claramente
  BFS de A\* em custo. Recomendo destacá-lo na análise.
- Nos cenários 01 e 02, os quatro algoritmos são difíceis de
  diferenciar em passos e custo. Diferenciam-se principalmente em
  estados expandidos e tempo.
- Os cenários 03, 04, 06 existem no repositório mas não fazem parte
  dos experimentos oficiais. Podem virar apêndice ou análise adicional
  se houver espaço.