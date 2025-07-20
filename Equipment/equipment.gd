extends Resource

class_name Equipment

enum Type {
	SWORD,
	BOW,
	ARMOR
}

@export var attack := 0
@export var defense := 0
@export var ability := ""

@export var name := ""
@export var description := ""
@export var type := Type.ARMOR
