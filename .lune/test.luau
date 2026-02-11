local process = require("@lune/process")

local result = process.exec("build/releases/rbx-screenshot_macos-aarch64", {
	"--fov",
	"70",
	"--output",
	".rodeo-screenshots/test-screenshot.png",
}, { stdio = "forward" })

if not result.ok then
	process.exit(result.code)
end
