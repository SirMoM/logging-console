extends Node


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var index = 16
	
	print(index && 16)
	print(index >> 1)
	print(index >> 1 == 1)
	print(checkbit(index, 5))

func checkbit(n, bit):
	return ((n & (1 << (bit - 1))) > 0)
