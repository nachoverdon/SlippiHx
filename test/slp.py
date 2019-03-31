from slippi import Game

game = None
replays = ['falco', 'fox', 'icsz']

for r in replays:
	game = Game(f'{r}.slp')
	print(r, game.metadata)