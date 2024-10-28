class_name TilesetWFC extends Resource
################################################################################
## Constants and Data

################################################################################
## Members

@export var tiles : Array[TileWFC]

################################################################################
## Public Methods

func get_tiles_ids() -> Array[String]:
	var tile_ids : Array[String]; tile_ids.assign(tiles.map(func(tile : TileWFC) -> String: return tile.get_id()))
	return tile_ids

func get_constraints_set(p_borders_set : Array[String]) -> Dictionary:
	var constraints_set : Dictionary = {}

	for tile in tiles:
		if not tile.is_format_ok(): return {}
		constraints_set[tile.get_id()] = {}
		for border_key in p_borders_set:
			constraints_set[tile.get_id()][border_key] = tile.get_border(border_key)

	return constraints_set

################################################################################
## Private Methods

################################################################################
## Setters/Getters
