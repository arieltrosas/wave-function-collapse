class_name TilesetWFC extends Resource
################################################################################
## Constants and Data

################################################################################
## Members

@export var tiles : Array[TileWFC]

################################################################################
## Public Methods

func get_tile_by_id(p_id : String) -> TileWFC:
	for tile in tiles:
		if tile.get_id() == p_id: return tile
	return null

func get_tile_ids() -> Array[String]:
	var tile_ids : Array[String]; tile_ids.assign(tiles.map(func(tile : TileWFC) -> String: return tile.get_id()))
	return tile_ids

func get_constraints(p_borders_set : Array[String]) -> Dictionary:
	var constraints : Dictionary = {}

	for tile in tiles:
		if not tile.is_format_ok(): return {}
		constraints[tile.get_id()] = {}
		for border_key in p_borders_set:
			constraints[tile.get_id()][border_key] = tile.get_border(border_key)

	return constraints

################################################################################
## Private Methods

################################################################################
## Setters/Getters
