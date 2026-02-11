local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

-- Clean + create build dir
if fs.isDir("build") then
	fs.removeDir("build")
end
fs.writeDir("build")

-- Read capture source and create darklua config with embedded capture script
local captureSource = fs.readFile(".rodeo/capture.luau")

local config = serde.decode("json", fs.readFile(".darklua.json"))
table.insert(config.rules, {
	rule = "inject_global_value",
	identifier = "CAPTURE_SOURCE",
	value = captureSource,
})
fs.writeFile("build/darklua.json", serde.encode("json", config))

-- Bundle with darklua (resolves @pkg/ requires into the output)
process.exec("darklua", { "process", "src/init.luau", "build/build.luau", "-c", "build/darklua.json" }, { stdio = "forward" })

-- Compile to standalone binaries for each platform
local targets = {
	{ os = "macos", arch = "aarch64", ext = "" },
	{ os = "macos", arch = "x86_64", ext = "" },
	{ os = "linux", arch = "x86_64", ext = "" },
	{ os = "windows", arch = "x86_64", ext = ".exe" },
}

fs.writeDir("build/releases")

for _, target in targets do
	local name = `rbx-screenshot_{target.os}-{target.arch}{target.ext}`
	local outputPath = `build/releases/{name}`
	local targetArg = `{target.os}-{target.arch}`

	process.exec("lune", { "build", "build/build.luau", "-o", outputPath, "--target", targetArg }, { stdio = "forward" })
end

print("Built all targets in build/releases/")
