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
		"puzzle_1": false,
		"laser_room_1": false,
		"laser_room_2": false,
		"chest_better_bow": false,
		"met_THE_prisoner": false,
		"met_sad_guy": false,
		"combat_room_2": false,
		"puzzle_2": false,
		"met_blacksmith": false,
		"blacksmith_armor_fixed": false,
		"THE_prisoner_after_blacksmith": false,
		"received_blacksmith_gift": false,
		"chest_lucky_armor": false,
		"combat_room_3": false
	},
	"dungeon_3": {
		"campfire_completed": false,
		"chest_icy_sword": false,
		"met_jester": false,
		"pin_1": false,
		"pin_2": false,
		"pin_3": false,
		"met_THE_prisoner": false,
		"received_jester_gift": false,
		"puzzle_1": false,
		"chest_revenge_armor": false,
		"before_THE_prisoner_fight": false
	},
	"throne_room_hall": {},
	"throne_room": {}
}
