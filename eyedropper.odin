package color_picker

import rl "vendor:raylib"
import "core:os"
import "core:c/libc"

SCREENSHOT_PATH :: "/tmp/_colorpick_screen.png"

eyedropper_capture :: proc() -> bool {
	when ODIN_OS == .Darwin {
		libc.system("screencapture -x /tmp/_colorpick_screen.png")
		return true
	} else when ODIN_OS == .Linux {
		if libc.system("which grim > /dev/null 2>&1") == 0 {
			libc.system("grim /tmp/_colorpick_screen.png")
			return true
		}
		if libc.system("which scrot > /dev/null 2>&1") == 0 {
			libc.system("scrot /tmp/_colorpick_screen.png")
			return true
		}
		if libc.system("which import > /dev/null 2>&1") == 0 {
			libc.system("import -window root /tmp/_colorpick_screen.png")
			return true
		}
		return false
	} else {
		return false
	}
}

eyedropper_cleanup :: proc() {
	os.remove(SCREENSHOT_PATH)
}
