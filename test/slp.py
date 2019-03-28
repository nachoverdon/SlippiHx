from slippi import Game

game = None
replays = ['falco', 'fox']

for r in replays:
	game = Game(f'{r}.slp')
	print(r, game.metadata)