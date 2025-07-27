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
	"dungeon_2": {
		"met_shopkeeper": false,
		"puzzle_started": false,
		"laser_room_1": false,
		"laser_room_2": false,
		"met_THE_prisoner": false
	}
}
