extends MMLayer
class_name MMMaskLayer

# warning-ignore:unused_class_variable
var mask : Texture2D

func get_layer_type() -> int:
	return LAYER_MASK

func duplicate():
	var layer = super.duplicate()
	return layer

func get_channels() -> Array:
	return [ "mask" ]
