package ui

import rl "vendor:raylib"

is_cmd_down :: proc() -> bool {
	return(
		rl.IsKeyDown(.LEFT_SUPER) ||
		rl.IsKeyDown(.RIGHT_SUPER) ||
		rl.IsKeyDown(.LEFT_CONTROL) ||
		rl.IsKeyDown(.RIGHT_CONTROL) \
	)
}
