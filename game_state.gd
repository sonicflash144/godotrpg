extends Resource

class_name GameState

@export var flags: Dictionary = {
	"prison0": {
		"checked_wall": false,
		"prison_door_opened": false,
	},
	"prison1": {
		"ate_sandwich": false,
	},
	"dungeon": {
		"met_princess": false,
		"hit_princess": false,
		"combat_room_2": false,
		"princess_apology": false,
		"visited_door": false,
		"princess_door_ready": false
	},
	"dungeon_2": {
		"campfire_completed": false,
		"met_shopkeeper": false,
		"chest_iron_sword": false,
		"chest_overpriced_armor": false,
		"combat_room_1": false,
		"puzzle_started": false,
		"puzzle_completed": false,
		"laser_room_1": false,
		"laser_room_2": false,
		"chest_revenge_armor": false,
		"met_THE_prisoner": false,
		"chest_better_bow": false
	}
}
