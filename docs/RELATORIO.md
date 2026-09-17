# Relatório Técnico — Agente de Combate à Dengue

## Modelagem do Problema

O ambiente é uma grade bidimensional. Cada posição livre representa um estado do
problema, e os vizinhos são gerados quando necessários.

- Estado inicial: célula `S`.
- Objetivo: célula `F`.
- Movimentos: cima, direita, baixo e esquerda.
- Obstáculos: células `#` não podem ser atravessadas.
- Custos: livre `1`, grama `2` e terreno difícil `4`.

Cada cenário JSON informa somente nome, mensagem educativa e grade. Ao carregar o
arquivo, `S` e `F` tornam-se posições, enquanto os símbolos da grade tornam-se tipos de
célula. O carregador verifica apenas o essencial: linhas regulares, símbolos conhecidos e
presença de origem e foco.

`GridProblem` oferece `initial_state`, `is_goal`, `successors` e `cost`. Assim, as buscas e
a interface usam a mesma regra de movimentação sem depender do formato JSON.

## Detalhes da Implementação

Os tipos de célula são representados por uma enumeração: livre, grama, terreno difícil e
obstáculo. O custo é associado à célula de destino do movimento, o que permite que uma
mesma rota tenha custos diferentes conforme o terreno atravessado. A ordem dos movimentos
(cima, direita, baixo e esquerda) é fixa para manter resultados reproduzíveis quando uma
busca encontrar alternativas equivalentes.

Os cenários são mantidos em arquivos JSON separados do código. Isso permite acrescentar ou
alterar mapas sem modificar as regras do domínio; o mesmo `GridProblem` é criado tanto para
a execução do jogador quanto para a do agente.

## Cenários

Foram preparados mapas com progressão de tamanho e de restrições. Os cenários simples,
intermediário e avançado introduzem corredores, bloqueios e terrenos de custo maior de forma
gradual. O cenário especialista amplia o espaço de busca com um trajeto longo e alternado,
enquanto o cenário complexo foi desenhado para contrastar uma rota curta em passos, porém
cara por atravessar terreno difícil, com uma rota mais longa e barata. Há também um desafio
sem rota, útil para verificar o comportamento do sistema quando o foco está isolado por
obstáculos.
