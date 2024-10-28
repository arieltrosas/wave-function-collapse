extends Node3D

const BORDERS : Array[String] = ["left","right","front","back"]

@export var tileset : TilesetWFC

func _ready() -> void:
	for tile in tileset.tiles:
		tile.load_from_file()

	var tile_ids : Array[String] = tileset.get_tiles_ids()
	var constraints_set : Dictionary = tileset.get_constraints_set(BORDERS)

	for id in tile_ids:
		var tile_constraints : Dictionary = constraints_set[id]
		print("Tile[%s]:" % id)
		print(JSON.stringify(tile_constraints,"\t",false))
		print()
