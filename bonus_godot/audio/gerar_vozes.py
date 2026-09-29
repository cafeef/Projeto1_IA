"""Gera as falas do jogo com uma voz neural em português (edge-tts).

Uso, a partir da raiz do repositório, no SEU computador (precisa de internet):
    pip install edge-tts
    python bonus_godot/audio/gerar_vozes.py                  # voz padrão (Francisca)
    python bonus_godot/audio/gerar_vozes.py --voz pt-BR-AntonioNeural
    python bonus_godot/audio/gerar_vozes.py --so-faltando    # não sobrescreve gravações
    python bonus_godot/audio/gerar_vozes.py --listar         # roteiro para gravar a própria voz

Cada frase de frases.json vira bonus_godot/audio/voz/<id>.mp3. Depois, abra o
projeto na Godot uma vez para ela importar os áudios. Se preferir gravar a voz
de alguém da equipe, salve com os mesmos nomes (.ogg, .mp3 ou .wav): o jogo
usa qualquer um dos três.
"""

import argparse
import asyncio
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
PHRASES = HERE / "frases.json"
OUT = HERE / "voz"

# Vozes neurais pt-BR boas para crianças: Francisca e Thalita (femininas),
# Antonio (masculina). Velocidade um pouco menor ajuda na compreensão.
DEFAULT_VOICE = "pt-BR-FranciscaNeural"
DEFAULT_RATE = "-10%"


def load_phrases() -> dict[str, str]:
    return json.loads(PHRASES.read_text(encoding="utf-8"))


def print_script(phrases: dict[str, str]) -> None:
    print("| Arquivo | Frase |")
    print("|---|---|")
    for key, text in phrases.items():
        print(f"| `{key}.ogg` | {text} |")


async def generate(phrases: dict[str, str], voice: str, rate: str, only_missing: bool) -> None:
    import edge_tts  # importado aqui para --listar funcionar sem a dependência

    OUT.mkdir(parents=True, exist_ok=True)
    for key, text in phrases.items():
        existing = [OUT / f"{key}.{ext}" for ext in ("ogg", "mp3", "wav")]
        if only_missing and any(p.exists() for p in existing):
            print(f"mantido  {key}")
            continue
        await edge_tts.Communicate(text, voice, rate=rate).save(str(OUT / f"{key}.mp3"))
        print(f"gerado   {key}.mp3")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--voz", default=DEFAULT_VOICE, help="nome da voz do edge-tts")
    parser.add_argument("--velocidade", default=DEFAULT_RATE, help='ex.: "-10%%", "+0%%"')
    parser.add_argument("--so-faltando", action="store_true", help="não sobrescreve arquivos existentes")
    parser.add_argument("--listar", action="store_true", help="mostra o roteiro de gravação e sai")
    args = parser.parse_args()

    phrases = load_phrases()
    if args.listar:
        print_script(phrases)
        return
    asyncio.run(generate(phrases, args.voz, args.velocidade, args.so_faltando))
    print(f"\n{len(phrases)} frases em {OUT}. Abra o projeto na Godot para importar os áudios.")


if __name__ == "__main__":
    main()
