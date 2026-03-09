package data

import rl "vendor:raylib"
import "core:os"
import "core:c/libc"

SCREENSHOT_PATH :: "/tmp/_colorpick_screen.png"

eyedropper_capture :: proc() -> bool {
	when ODIN_OS == .Darwin {
		log_info("Eyedropper: running screencapture")
		ret := libc.system("screencapture -x /tmp/_colorpick_screen.png")
		if ret != 0 {
			log_error("screencapture failed with code %d", ret)
			return false
		}
		if !os.exists(SCREENSHOT_PATH) {
			log_error("Screenshot file not created at %s", SCREENSHOT_PATH)
			return false
		}
		return true
	} else when ODIN_OS == .Linux {
		if libc.system("which grim > /dev/null 2>&1") == 0 {
			log_info("Eyedropper: running grim")
			libc.system("grim /tmp/_colorpick_screen.png")
			return true
		}
		if libc.system("which scrot > /dev/null 2>&1") == 0 {
			log_info("Eyedropper: running scrot")
			libc.system("scrot /tmp/_colorpick_screen.png")
			return true
		}
		if libc.system("which import > /dev/null 2>&1") == 0 {
			log_info("Eyedropper: running import")
			libc.system("import -window root /tmp/_colorpick_screen.png")
			return true
		}
		log_error("No screenshot tool found (tried grim, scrot, import)")
		return false
	} else {
		return false
	}
}

eyedropper_cleanup :: proc() {
	os.remove(SCREENSHOT_PATH)
}
