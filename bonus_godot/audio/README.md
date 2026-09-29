# Vozes do jogo

O jogo lê em voz alta as instruções, os avisos e o cartão educativo. Para cada frase de
`frases.json`, ele procura uma gravação em `voz/<id>.ogg`, `.mp3` ou `.wav`. Se faltar alguma
gravação, usa a voz do sistema, que no Linux costuma soar robótica.

Há dois jeitos de ter uma voz natural.

## Opção 1 — gravar a voz de alguém da equipe (a mais humanizada)

1. Veja o roteiro com os nomes dos arquivos: `python bonus_godot/audio/gerar_vozes.py --listar`.
2. Grave cada frase no celular ou no computador (por exemplo, com o Audacity), num lugar
   silencioso, falando devagar e com entonação alegre, como para uma criança.
3. Salve em `bonus_godot/audio/voz/` com o nome exato do roteiro (`instrucoes.ogg`,
   `msg_pneu.ogg`...). OGG, MP3 ou WAV funcionam.
4. Abra o projeto na Godot uma vez para ela importar os arquivos.

Gravações próprias também evitam qualquer dúvida de licença se o jogo for publicado no site do
LESIC.

## Opção 2 — gerar com voz neural (Francisca, da Microsoft)

No seu computador, com internet:

```bash
pip install edge-tts
python bonus_godot/audio/gerar_vozes.py            # gera voz/<id>.mp3 para as 26 frases
python bonus_godot/audio/gerar_vozes.py --voz pt-BR-AntonioNeural   # voz masculina
```

A velocidade padrão é 10% mais lenta, para facilitar a compreensão (`--velocidade`). Use
`--so-faltando` para gerar só o que ainda não foi gravado, sem sobrescrever gravações próprias.
O serviço é o mesmo do "Ler em voz alta" do Microsoft Edge. Para uso acadêmico não há problema;
antes de publicar o jogo, confira os termos de uso ou prefira a Opção 1.

## Quando a voz toca

- Botão azul com alto-falante: sempre (gravação ou, se faltar, voz do sistema).
- Avisos da vez do robô e leitura automática do cartão final: só quando existem gravações,
  para não tocar a voz robótica sem a criança pedir.

Se mudar um texto em `frases.json`, grave ou gere de novo o arquivo correspondente.
