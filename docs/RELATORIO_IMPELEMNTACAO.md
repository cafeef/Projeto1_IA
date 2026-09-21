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