extends Node
class_name HexDirections

enum direction { NE, E, SE, SW, W, NW }

static func opposite(direction :int) -> int:
	return (direction + 3) if direction < 3 else (direction - 3)

static func previous(direction: int) -> int:
	return HexDirections.direction.NW if direction == HexDirections.direction.NE else direction - 1

static func next(direction: int) -> int:
	return HexDirections.direction.NE if direction == HexDirections.direction.NW else direction + 1
