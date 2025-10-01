extends Node2D
class_name prop


@onready var prop_sprites: Node2D = $propSprites
@onready var zPosition : float = self.global_position.y

func _ready() -> void:
	
#	sprites track their coordinates from their center, so yOffset makes sure their Z level is related to their Bottom
	#var yOffset : float;
	
#	this orders the sprites when they spawn, so you dont have to do it manually
	for propSprite : Sprite2D in prop_sprites.get_children():
		#yOffset = propSprite.global_position.y + propSprite.texture.get_height()/2.0 
		
		if  zPosition < RenderingServer.CANVAS_ITEM_Z_MAX and zPosition > RenderingServer.CANVAS_ITEM_Z_MIN:
			propSprite.z_index = int(zPosition)
		else :
			print("WARNING THIS BITCH TOO FAR UP OR DOWN. i cant render this bitch's Z index: " + str(propSprite))
