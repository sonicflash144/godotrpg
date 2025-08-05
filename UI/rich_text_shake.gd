@tool
class_name RichTextShake extends RichTextEffect

# This script implements a [shake] BBCode tag.
# Usage: [shake strength=10 rate=5]Shaking Text[/shake]
#
# Parameters:
# - strength: (float, default 10.0) How far the characters move.
# - rate: (float, default 5.0) How quickly the characters shake.

var bbcode = "custom_shake"
var rng = RandomNumberGenerator.new()

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# --- Get Parameters ---
	# Fetch strength and rate from the BBCode tag, using defaults if not provided.
	var strength = float(char_fx.env.get("strength", 10.0))
	var rate = float(char_fx.env.get("rate", 10.0))

	# --- Time Calculation ---
	# This logic determines when to pick a new random position, based on the rate.
	# It ensures the shake is smooth and timed correctly.
	# Avoid division by zero.
	var update_interval = 0.5 / max(0.01, rate)
	# Determine the start time of the current shake movement.
	var current_interval_start_time = floor(char_fx.elapsed_time / update_interval) * update_interval

	# --- Deterministic Randomness ---
	# We create a unique seed for each character to ensure each one shakes
	# differently, but predictably, every time the dialogue runs.
	# In Godot 4, `glyph_index` provides the stable index for this purpose.
	var char_seed = char_fx.glyph_index # <-- CORRECTED LINE
	
	# Generate seeds for the previous and current shake targets based on the character and time.
	var seed_for_previous = hash(str(char_seed) + str(current_interval_start_time - update_interval))
	var seed_for_current = hash(str(char_seed) + str(current_interval_start_time))

	# --- Calculate Shake Positions ---
	# This section mirrors the C++ logic to find two random points (previous and current)
	# and then interpolate between them.

	# Get the random value for the previous target position.
	rng.seed = seed_for_previous
	var char_previous_rand = rng.randi()
	# Remap the random value to a random angle (in radians).
	var previous_offset_angle = remap(float(char_previous_rand % 2147483647), 0.0, 2147483647.0, 0.0, 2.0 * PI)
	
	# Get the random value for the current target position.
	rng.seed = seed_for_current
	var char_current_rand = rng.randi()
	# Remap the random value to a random angle.
	var current_offset_angle = remap(float(char_current_rand % 2147483647), 0.0, 2147483647.0, 0.0, 2.0 * PI)
	
	# --- Interpolation ---
	# Calculate the progress (from 0.0 to 1.0) within the current movement.
	var time_in_interval = char_fx.elapsed_time - current_interval_start_time
	var n_time = clamp(time_in_interval / update_interval, 0.0, 1.0)

	# Create direction vectors from the angles.
	var prev_vec = Vector2(sin(previous_offset_angle), cos(previous_offset_angle))
	var curr_vec = Vector2(sin(current_offset_angle), cos(current_offset_angle))

	# --- Apply Effect ---
	# Linearly interpolate between the previous and current target vectors.
	# The '/ 10.0' factor is kept from the original C++ logic to match the shake intensity.
	char_fx.offset = prev_vec.lerp(curr_vec, n_time) * (strength / 10.0)

	return true # Return true to apply the calculated offset.
