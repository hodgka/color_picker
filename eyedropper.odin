package color_picker

import "core:os"
import "core:c/libc"

SCREENSHOT_PATH :: "/tmp/_colorpick_screen.png"

eyedropper_capture :: proc() -> bool {
	os.remove(SCREENSHOT_PATH)

	when ODIN_OS == .Darwin {
		// Try full screen capture first (requires Screen Recording permission)
		libc.system("screencapture -x /tmp/_colorpick_screen.png 2>/dev/null")
		if os.exists(SCREENSHOT_PATH) do return true

		// Fallback: interactive selection mode (works without full permission)
		libc.system("screencapture -i /tmp/_colorpick_screen.png 2>/dev/null")
		if os.exists(SCREENSHOT_PATH) do return true
		return false
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
