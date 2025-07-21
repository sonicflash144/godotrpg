extends Resource

class_name Equipment

enum Type {
	SWORD,
	BOW,
	ARMOR
}
@export_category("Stats")
@export var attack := 0
@export var defense := 0
@export var ability := ""

@export_category("Metadata")
@export var name := ""
@export var type := Type.ARMOR
@export var description := ""
