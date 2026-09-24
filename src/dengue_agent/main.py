"""Ponto de entrada: uv run dengue"""

import arcade

from .ui.app import GameWindow


def main() -> None:
    GameWindow()
    arcade.run()


if __name__ == "__main__":
    main()
