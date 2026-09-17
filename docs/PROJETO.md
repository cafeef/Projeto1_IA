# Universidade Tecnológica Federal do Paraná

## Campus Ponta Grossa

### Curso Superior em Bacharelado em Ciência da Computação (BCC)

**Disciplina:** Inteligência Artificial

# Projeto nº 1 – Resolução de Problema por meio de Algoritmos de Busca

## 1. INSTRUÇÕES

### 1.1 Equipe

1.1.2. Este trabalho deverá ser feito em equipe com no máximo 4 alunos.

1.1.3. Os nomes dos membros das equipes deverão ser adicionados no arquivo compartilhado no Drive até a data limite 16/09/2026.

### 1.2 Desenvolvimento do Projeto

1.2.1. Implementação dos algoritmos para resolução do problema (descrito na Seção 2) em uma linguagem de programação.

1.2.2. Elaboração de um relatório técnico (detalhado), conforme instruções no Apêndice A e nas normas de trabalho acadêmico da UTFPR, disponível em:

<https://www.utfpr.edu.br/bibliotecas/trabalhos-academicos/orientacoes-para-entrega>

(Modelo para entrega de trabalhos acadêmicos regulares sem licença Creative Commons).

### 1.3 Entrega e Postagem do Projeto

1.3.1. A data de entrega do projeto, com postagem no Moodle, tem como data limite 02/10/2026.

1.3.2. Apenas 1 (um) integrante da equipe deverá fazer a postagem no Moodle.

1.3.3. Deverá ser postado um arquivo compactado (`.zip` ou `.rar`) contendo os códigos-fonte e executável (bibliotecas e demais componentes necessários) e o relatório técnico no ambiente virtual de aprendizagem (Moodle).

1.3.4. A não postagem de algum dos itens citados (código e relatório) configura a não entrega do trabalho.

### 1.4 Apresentação do projeto (defesa)

1.4.1. A apresentação do projeto será feita em sala de aula, de forma presencial e obrigatória, e tem como início a data 05/10/2026.

1.4.2. Os integrantes da equipe devem estar presentes no dia e horário agendado. A ausência do aluno no horário agendado configura falta da mesma maneira que em avaliação presencial escrita.

1.4.3. Durante a apresentação serão feitas perguntas para cada integrante da equipe.

### 1.5 Critérios da avaliação e valor de cada atividade

#### 1.5.1 Itens a serem avaliados

- Modelagem;
- implementação correta dos algoritmos;
- qualidade da heurística;
- clareza do relatório;
- qualidade da análise crítica;
- organização do código.

#### 1.5.2

O projeto tem valor igual a 3,5 pts (três inteiros e cinco décimos), computados conforme mostra o Quadro 1. Mais detalhes são apresentados no Apêndice B.

**Quadro 1 – Itens de avaliação do projeto**

| Descrição | Nota (pts) |
|---|---:|
| Implementação | 2,0 |
| Relatório técnico | 1,0 |
| Apresentação/Avaliação individual | 0,5 |
| **TOTAL** | **3,5** |

#### 1.5.3

Ressalta-se que a avaliação do relatório técnico está condicionada à implementação completa do projeto conforme a descrição. Caso a equipe, por exemplo, não implemente alguma funcionalidade solicitada, isso refletirá na nota da avaliação do relatório e também na apresentação.

> **OBSERVAÇÃO:** Indícios de cópia, menores que sejam, resultarão em nota final igual a 0 (zero) no projeto.

## 2. PROBLEMA – Inteligência Artificial Aplicada ao Combate à Dengue

### 2.1 Objetivo

Este projeto tem como objetivo consolidar os seguintes conceitos:

- representação de problemas;
- espaço de estados;
- busca sem informação;
- algoritmos de busca com informação ou busca heurística;
- comparação entre estratégias de busca;
- análise experimental de algoritmos;
- comparação entre decisão humana e decisão algorítmica;
- aplicação da Inteligência Artificial em um problema de interesse social.

### 2.2 Contextualização

A dengue é uma doença transmitida pelo mosquito *Aedes aegypti*. A prevenção depende, entre outras ações, da eliminação de locais que possam acumular água e servir como criadouros do mosquito.

Neste projeto deverá ser desenvolvido um ambiente computacional de simulação (jogo) que represente um espaço no qual existam possíveis focos de proliferação do mosquito da dengue.

O ambiente poderá representar, por exemplo:

- um quintal;
- uma praça;
- uma escola;
- um conjunto de residências;
- um pequeno bairro.

No cenário poderão existir elementos como:

- pneus;
- vasos e pratos de plantas;
- garrafas;
- baldes;
- recipientes destampados;
- caixas-d'água inadequadamente fechadas;
- calhas;
- outros locais com possibilidade de acúmulo de água.

O ambiente deverá possuir dois participantes:

- **Usuário:** controla manualmente um personagem.
- **Agente Inteligente:** controla automaticamente outro personagem por meio de um algoritmo de busca.

O usuário e o agente inteligente deverão resolver a mesma instância do problema, considerando o mesmo cenário, a mesma posição de origem e o mesmo foco como objetivo. A interface poderá apresentar as duas execuções em áreas distintas ou utilizar outra solução visual que permita acompanhar adequadamente ambos os participantes. Durante a execução, ambos deverão se deslocar pelo mesmo ambiente, permitindo acompanhar e comparar a solução produzida pela decisão humana e pela estratégia de busca utilizada pelo agente.

O objetivo não é apenas alcançar o foco, mas observar como diferentes formas de resolução do problema produzem resultados distintos em termos de:

- caminho percorrido;
- quantidade de passos;
- custo;
- tempo;
- quantidade de estados explorados.

### 2.3 Modelagem do Problema

O ambiente deverá ser representado por uma matriz bidimensional (grade), na qual cada célula corresponde a uma posição possível no cenário.

A matriz deverá representar elementos como:

- posição inicial da missão;
- foco de dengue a ser alcançado;
- caminhos livres;
- obstáculos;
- diferentes tipos de terreno;
- custos de deslocamento.

Cada célula válida da matriz corresponde a um estado possível do agente. Os movimentos entre células adjacentes definem implicitamente um grafo de busca, em que:

- **nós:** correspondem às posições válidas da matriz;
- **arestas:** correspondem aos movimentos possíveis entre posições vizinhas;
- **pesos das arestas:** correspondem aos custos de deslocamento entre as células.

O agente poderá realizar os seguintes movimentos: cima, baixo, esquerda e direita. Movimentos que levem o agente para fora dos limites da matriz ou para uma célula definida como obstáculo não serão permitidos.

#### 2.3.1 Elementos mínimos do ambiente

O cenário deverá conter, obrigatoriamente:

- uma posição inicial para a missão;
- pelo menos um foco de dengue;
- células livres para deslocamento;
- obstáculos;
- pelo menos dois tipos de terreno com custos diferentes.

Uma possível definição de custos é apresentada a seguir:

| Tipo de célula | Custo de deslocamento |
|---|---:|
| Caminho livre / calçada | 1 |
| Grama | 2 |
| Terreno de difícil acesso | 4 |
| Obstáculo | não permitido |

Os valores poderão ser modificados pela equipe, desde que sejam positivos, coerentes com o problema e devidamente justificados no relatório.

#### 2.3.2 Formulação do problema de busca

A equipe deverá definir formalmente:

- **Estado inicial:** posição de origem definida para a missão, utilizada tanto pelo usuário quanto pelo agente inteligente.
- **Estado objetivo:** posição do foco de dengue que deverá ser alcançado.
- **Estados:** todas as posições válidas que o agente pode ocupar.
- **Ações:** movimentos permitidos para cima, baixo, esquerda e direita.
- **Função sucessor:** conjunto de estados válidos que podem ser alcançados a partir da posição atual.
- **Teste de objetivo:** verifica se a posição atual do agente corresponde à posição do foco selecionado.
- **Custo do caminho:** soma dos custos associados às células percorridas durante o deslocamento.

Embora o ambiente seja visualmente representado por uma matriz, os algoritmos de busca deverão tratá-lo como um espaço de estados em forma de grafo implícito. Assim, não é necessário construir previamente um grafo explícito com todos os nós e arestas. Os estados vizinhos poderão ser gerados dinamicamente a partir da posição atual do agente. Essa formulação permite aplicar diretamente os algoritmos BFS, DFS, Busca Gulosa e A*.

### 2.4 Funcionamento do ambiente/jogo

O ambiente deverá permitir a atuação simultânea do usuário e do agente inteligente no mesmo cenário. Antes do início da execução, deverão ser definidos:

- o cenário;
- o foco de dengue que deverá ser alcançado;
- a posição inicial;
- o algoritmo de busca utilizado pelo agente.

Usuário e agente deverão resolver a mesma instância do problema, considerando a mesma posição de origem e o mesmo foco como objetivo. Após o início da missão, ambos poderão percorrer caminhos diferentes até alcançar o foco selecionado.

#### 2.4.1 Usuário

O usuário deverá controlar manualmente seu personagem pelo ambiente. A cada movimento, o sistema deverá:

- atualizar a posição do usuário;
- impedir movimentos inválidos;
- impedir passagem por obstáculos;
- registrar o caminho percorrido;
- acumular o custo do deslocamento;
- contabilizar a quantidade de passos;
- registrar o tempo necessário para alcançar o objetivo.

O usuário poderá movimentar-se para cima, para baixo, para a esquerda e para a direita.

#### 2.4.2 Agente Inteligente

Simultaneamente ao usuário, o agente deverá buscar automaticamente o mesmo foco utilizando um dos algoritmos implementados:

- BFS;
- DFS;
- Busca Gulosa;
- A*.

O agente deverá considerar a mesma posição de origem e o mesmo objetivo definidos para a missão e buscar o mesmo objetivo. Durante a execução deverá ser possível acompanhar visualmente:

- o deslocamento do agente;
- os estados explorados;
- o caminho percorrido ou o caminho final encontrado;
- a posição do objetivo.

O sistema deverá registrar:

- caminho encontrado;
- quantidade de passos;
- custo total;
- estados expandidos;
- estados gerados;
- tempo de execução;
- tamanho máximo da fronteira.

#### 2.4.3 Sincronização da execução

Usuário e agente deverão atuar no mesmo cenário e na mesma missão. A equipe poderá definir uma estratégia adequada para sincronizar a execução, desde que seja possível acompanhar visualmente o desempenho dos dois participantes.

Durante a interação, o usuário poderá competir visualmente com um dos quatro algoritmos de busca, selecionado antes do início da missão. O agente deverá executar a busca e percorrer o caminho correspondente ao algoritmo selecionado.

A missão deverá permanecer ativa até que usuário e agente tenham alcançado o foco, mesmo que um deles chegue antes.

Para fins de análise experimental, o usuário deverá realizar uma única execução manual por cenário. Em seguida, os algoritmos BFS, DFS, Busca Gulosa e A* deverão resolver a mesma instância do problema. Dessa forma, evita-se que o desempenho do usuário seja influenciado pelo aprendizado decorrente da repetição do mesmo cenário.

O tempo de execução do algoritmo deverá ser medido separadamente do tempo utilizado para a representação visual do deslocamento do agente.

#### 2.4.4 Término da missão

Ao alcançar o foco, deverá ser apresentada uma mensagem educativa relacionada ao elemento encontrado, contendo uma orientação de prevenção ou eliminação daquele possível criadouro.

**Exemplo:** “Pneu com água acumulada” — Pneus expostos podem acumular água e favorecer a proliferação do mosquito. Devem ser armazenados em local coberto ou receber destinação adequada.

Ao término da missão deverão ser apresentados os resultados do usuário e do agente.

### 2.5 Cenários

A equipe deverá desenvolver pelo menos três cenários com diferentes níveis de complexidade.

#### Cenário 1 – Simples

Deverá possuir:

- mapa menor;
- poucos obstáculos;
- poucos caminhos alternativos;
- custos predominantemente uniformes.

#### Cenário 2 – Intermediário

Deverá possuir:

- ambiente maior;
- maior quantidade de obstáculos;
- diferentes possibilidades de caminho.

#### Cenário 3 – Complexo

Deverá possuir:

- ambiente maior;
- múltiplos caminhos;
- obstáculos;
- diferentes tipos de terreno;
- diferentes custos de deslocamento.

O terceiro cenário deverá permitir observar situações em que o caminho com menor quantidade de passos não corresponda necessariamente ao caminho de menor custo.

### 2.6 Algoritmos de Busca

- **Busca em Largura (BFS):** busca sem informação que explora os estados por níveis.
- **Busca em Profundidade (DFS):** busca sem informação que aprofunda um caminho antes de explorar alternativas.
- **Busca Gulosa:** utiliza exclusivamente a informação heurística: `f(n) = h(n)`, em que `h(n)` corresponde à estimativa entre o estado atual e o objetivo.
- **A*:** combina o custo já percorrido com uma estimativa do custo restante: `f(n) = g(n) + h(n)`, em que `g(n)` representa o custo acumulado desde o estado inicial e `h(n)` representa uma estimativa do custo restante até o objetivo.

Para os algoritmos Busca Gulosa e A* deverá ser implementada uma função heurística. Como sugestão, poderá ser utilizada a Distância Manhattan. Considerando diferentes custos de terreno, a equipe deverá verificar sua compatibilidade com a função custo utilizada. Uma possibilidade é multiplicar a Distância Manhattan pelo menor custo possível de um movimento no ambiente.

No relatório deverá constar:

- definição da heurística;
- explicação de seu funcionamento;
- justificativa para sua utilização;
- discussão sobre sua admissibilidade para o problema modelado.

### 2.7 Comparação entre Usuário e Agente

Após a execução, o sistema deverá apresentar uma comparação entre os resultados do usuário e do agente inteligente.

Para o usuário deverão ser apresentados:

- caminho percorrido;
- quantidade de passos;
- custo total;
- tempo necessário para alcançar o foco.

Para o agente deverão ser apresentados:

- caminho encontrado;
- quantidade de passos;
- custo total;
- estados expandidos;
- estados gerados;
- tempo;
- tamanho máximo da fronteira.

O sistema poderá indicar visualmente quem alcançou primeiro o objetivo. Entretanto, para fins de análise dos algoritmos, deverão ser consideradas as métricas computacionais definidas na seção de experimentos.

### 2.8 Experimentos Obrigatórios

Cada cenário deverá ser executado utilizando:

- usuário;
- BFS;
- DFS;
- Busca Gulosa;
- A*.

Para cada cenário deverá ser realizada:

- uma execução manual pelo usuário;
- uma execução da BFS;
- uma execução da DFS;
- uma execução da Busca Gulosa;
- uma execução do A*.

Considerando os três cenários, serão realizadas 3 execuções humanas e 12 execuções algorítmicas, totalizando 15 execuções.

Cada execução deverá registrar:

- caminho;
- quantidade de passos;
- custo final;
- tempo;
- estados expandidos, quando aplicável;
- estados gerados, quando aplicável;
- tamanho máximo da fronteira, quando aplicável.

Os resultados deverão ser apresentados por meio de tabelas e gráficos.

### 2.9 Análise Comparativa

No relatório deverão ser respondidas obrigatoriamente as seguintes questões:

1. Todos os algoritmos encontraram solução em todos os cenários?
2. Qual algoritmo expandiu mais estados?
3. Qual algoritmo apresentou maior tamanho de fronteira?
4. A DFS apresentou algum comportamento desfavorável?
5. BFS encontrou o caminho com menor quantidade de passos?
6. O caminho com menos passos foi sempre o caminho de menor custo?
7. A Busca Gulosa encontrou a solução de menor custo?
8. A* encontrou a solução de menor custo?
9. A heurística influenciou o desempenho?
10. Qual algoritmo apresentou melhor desempenho nos cenários mais complexos?
11. O usuário conseguiu obter menor custo que algum dos algoritmos?
12. Usuário e agente escolheram caminhos diferentes?
13. Em quais situações o agente superou claramente o usuário?
14. Em quais situações o usuário apresentou desempenho semelhante ou superior?
15. Qual algoritmo seria mais adequado para esse problema?

### 2.10 Interface

A implementação básica deverá possuir uma interface suficiente para permitir:

- visualizar o ambiente;
- identificar o usuário;
- identificar o agente inteligente;
- identificar obstáculos;
- identificar focos;
- identificar diferentes tipos de terreno;
- controlar manualmente o usuário;
- selecionar o algoritmo do agente;
- acompanhar simultaneamente usuário e agente;
- visualizar os estados explorados pelo algoritmo;
- visualizar os caminhos percorridos;
- apresentar os resultados.

### 2.11 Jogo Educacional (Opcional – Bônus)

Serão bonificadas com pontuação extra de até 1,5 ponto as equipes que transformarem o ambiente de simulação em um jogo educacional totalmente funcional, com interface gráfica adequada e sem erros que comprometam seu funcionamento.

O jogo deverá ser desenvolvido considerando como público-alvo alunos com deficiência intelectual e crianças do Ensino Fundamental, buscando apresentar uma interação simples, compreensível e adequada às características desses usuários.

As equipes que desenvolverem o jogo deverão considerar aspectos como clareza das instruções, simplicidade da interface, facilidade de interação, legibilidade dos elementos visuais e apresentação objetiva das informações educativas relacionadas à prevenção da dengue.

Os jogos que atenderem adequadamente aos requisitos poderão ser disponibilizados no site do LESIC para utilização pelos alunos da Escola Dra. Zilda Arns, mantida pela Associação Artesanal do Excepcional de Ponta Grossa (ASSARTE), bem como por outros públicos compatíveis com a proposta educacional.

#### Observações finais importantes

- O código deverá ser autoral.
- Não será permitido utilizar bibliotecas prontas para os algoritmos de busca.
- A demonstração prática será obrigatória.
- Todos os membros deverão ser capazes de explicar a implementação.
- Os cenários utilizados nos experimentos deverão permitir comparação efetiva entre os algoritmos.

## APÊNDICE A – RELATÓRIO TÉCNICO

O relatório técnico deve apresentar as seguintes seções:

### 1. Introdução

Apresentar brevemente o problema abordado, relacionado à prevenção e ao combate à dengue, o objetivo do projeto e os algoritmos implementados (Busca em Largura, Busca em Profundidade, Busca Gulosa e A*). Espera-se ainda que seja abordada a importância da representação de problemas em espaços de estados, da utilização de algoritmos de busca na resolução de problemas e da comparação entre a solução encontrada pelo usuário e pelo agente inteligente.

### 2. Modelagem do Problema

Descrever como o ambiente foi representado computacionalmente, incluindo: definição da matriz bidimensional, dimensões utilizadas, tipos de células, posição inicial, posição dos focos de dengue, obstáculos, tipos de terreno e respectivos custos de deslocamento. Deve-se ainda explicar como a matriz corresponde a um grafo implícito de estados, indicando como são definidos os estados, ações possíveis, função sucessor, teste de objetivo e custo do caminho.

### 3. Desenvolvimento e Funcionamento do Ambiente

Descrever o funcionamento geral do ambiente de simulação, incluindo a interação do usuário e a atuação do agente inteligente. Explicar como são definidos os cenários, a posição inicial e o foco a ser alcançado, bem como a forma utilizada para garantir que usuário e agente resolvam a mesma instância do problema. Apresentar ainda como ocorre a execução de ambos, como os movimentos do usuário são realizados e como o deslocamento do agente é apresentado visualmente.

### 4. Implementação dos Algoritmos

Descrever detalhadamente os algoritmos implementados: Busca em Largura (BFS), Busca em Profundidade (DFS), Busca Gulosa e A*. Para cada algoritmo, explicar seu funcionamento, as estruturas de dados utilizadas, o tratamento dos estados visitados, a geração dos sucessores e a reconstrução do caminho final. Para Busca Gulosa e A*, apresentar também as funções de avaliação utilizadas.

### 5. Heurística Utilizada

Apresentar a heurística utilizada nos algoritmos Busca Gulosa e A*, explicando sua fórmula, como é calculada, por que ela é adequada ao problema e sua relação com os custos de deslocamento definidos no ambiente. Deve-se também apresentar uma discussão sobre admissibilidade e, quando pertinente, consistência da heurística.

### 6. Conteúdo Educacional

Apresentar os tipos de focos de dengue utilizados no ambiente e as informações educativas associadas a cada um deles. Explicar como essas informações são apresentadas ao usuário e citar as fontes confiáveis utilizadas para a elaboração do conteúdo relacionado à prevenção da dengue.

### 7. Experimentos Realizados

Descrever os cenários utilizados nos experimentos, incluindo suas características, nível de complexidade, posição inicial, foco selecionado, obstáculos e custos de terreno. Apresentar as execuções realizadas pelo usuário e pelos algoritmos BFS, DFS, Busca Gulosa e A*. Os resultados deverão ser organizados em tabelas e, quando pertinente, gráficos.

**Exemplo de tabela:**

| Cenário | Método | Passos | Custo | Tempo | Estados Expandidos | Estados Gerados | Etc. |
|---|---|---:|---:|---:|---:|---:|---|
| Cenário 1 | Usuário |  |  |  | — | — |  |
| Cenário 1 | BFS |  |  |  |  |  |  |
| Cenário 1 | DFS |  |  |  |  |  |  |
| Cenário 1 | Gulosa |  |  |  |  |  |  |
| Cenário 1 | A* |  |  |  |  |  |  |

### 8. Análise dos Resultados

Interpretar e comparar os resultados obtidos, não se limitando à apresentação de valores numéricos. A análise deverá abordar questões como:

1. Todos os algoritmos encontraram solução em todos os cenários?
2. Qual algoritmo encontrou o caminho com menor quantidade de passos?
3. O caminho com menor quantidade de passos também apresentou o menor custo?
4. Qual algoritmo expandiu mais estados?
5. Qual apresentou maior tamanho de fronteira?
6. A Busca Gulosa encontrou a solução de menor custo?
7. O A* apresentou melhor desempenho nos cenários mais complexos?
8. A heurística contribuiu para reduzir a exploração do espaço de estados?
9. O usuário tomou decisões diferentes do agente inteligente?
10. Em quais situações o usuário apresentou desempenho semelhante ou superior ao agente?
11. Qual estratégia se mostrou mais adequada ao problema?

A análise não deve se limitar a essas questões.

### 9. Conclusão

Apresentar os principais resultados e aprendizados obtidos com o desenvolvimento do projeto, destacando a comparação entre as estratégias de busca e entre a solução humana e a solução algorítmica. Devem ser discutidas também as limitações da implementação, dificuldades encontradas e possíveis melhorias ou extensões do ambiente.

### 10. Referências

Inserir as referências usadas no trabalho e formatá-las conforme as normas ABNT.

## APÊNDICE B – AVALIAÇÃO DO PROJETO

### 1. Implementação do Sistema (2,0 pontos)

Avalia a qualidade técnica da solução desenvolvida.

| Itens avaliados | Pontos |
|---|---:|
| Modelagem correta do ambiente | 0,20 |
| Funcionamento do usuário | 0,15 |
| Funcionamento simultâneo usuário/agente | 0,10 |
| Implementação correta da BFS | 0,25 |
| Implementação correta da DFS | 0,25 |
| Implementação correta da busca gulosa | 0,25 |
| Implementação correta da busca A* | 0,30 |
| Heurística | 0,15 |
| Conteúdo educacional | 0,10 |
| Cenários e geração dos resultados | 0,25 |
| **TOTAL** | **2,00** |

### 2. Relatório Técnico (1,0 ponto)

| Seção do relatório | Critério avaliado | Pontos |
|---|---|---:|
| 1. Introdução | Contextualização do problema, objetivos do projeto e apresentação dos algoritmos implementados | 0,05 |
| 2. Modelagem do Problema | Clareza e correção na representação da matriz, estados, ações, sucessores, objetivo e custos | 0,15 |
| 3. Desenvolvimento e Funcionamento do Ambiente | Descrição do ambiente, interação do usuário e atuação do agente inteligente | 0,10 |
| 4. Implementação dos Algoritmos | Explicação correta de BFS, DFS, Gulosa e A*, estruturas utilizadas e reconstrução do caminho | 0,15 |
| 5. Heurística Utilizada | Definição, justificativa, relação com custos, admissibilidade e consistência | 0,10 |
| 6. Conteúdo Educacional | Qualidade das informações sobre prevenção da dengue e uso de fontes confiáveis | 0,05 |
| 7. Experimentos Realizados | Descrição dos cenários, organização dos testes, tabelas e gráficos | 0,15 |
| 8. Análise dos Resultados | Qualidade da interpretação, comparação entre algoritmos e entre usuário e agente | 0,15 |
| 9. Conclusão | Síntese dos resultados, limitações, aprendizados e melhorias | 0,05 |
| 10. Referências / organização textual | Referências adequadas, clareza, organização e qualidade geral da escrita | 0,05 |
| **TOTAL** |  | **1,00** |

> **Observação:** A avaliação do relatório técnico considerará tanto a presença das seções solicitadas quanto a qualidade, correção e profundidade das informações apresentadas. A simples inclusão de uma seção não garante a pontuação integral correspondente.

### 3. Apresentação Oral (0,5 pontos)

A equipe deverá apresentar e demonstrar o funcionamento do sistema.

| Itens avaliados | Pontos |
|---|---:|
| Clareza na explicação do problema | 0,1 |
| Demonstração prática | 0,1 |
| Explicação dos algoritmos | 0,1 |
| Discussão dos resultados | 0,1 |
| Respostas às perguntas individuais | 0,1 |
| **TOTAL** | **0,5** |

### 4. Bônus (até +1,5 pontos)

| Recurso adicional | Pontos |
|---|---:|
| Transformação em jogo educacional completo | até 0,5 |
| Animações e recursos de interação | até 0,3 |
| Fases, missões ou níveis adicionais | até 0,2 |
| Geração automática/editor de cenários | até 0,2 |
| Outros recursos relevantes | até 0,3 |
| **Bônus máximo** | **1,5** |

Os pontos de bônus só serão atribuídos se a implementação básica estiver funcionando corretamente.
