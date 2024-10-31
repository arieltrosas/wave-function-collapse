extends Node3D

const TileID : String = "01"
const PlacePosition : Vector3i = Vector3i(2,1,2)

func _ready() -> void:
	var node_wfc : NodeWFC = $NodeWFC
	node_wfc.collapse()
