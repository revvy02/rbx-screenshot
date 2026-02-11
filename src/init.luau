-- Capture a screenshot via rodeo exec, find the resulting file by timestamp,
-- and optionally copy it to an output path.
--
-- Usage:
--   rbx-screenshot [--cframe <expr>] [--fov <number>] [--settle <seconds>] [-o <path>]

local fs = require("@lune/fs")
local process = require("@lune/process")
local argparse = require("@pkg/argparse")
local log = require("@self/log")

local CAPTURE_DIR = `{process.env.HOME}/Library/Roblox/tmp-capture-storage`
local DEFAULT_OUTPUT_DIR = ".rodeo-screenshots"

local parser = argparse()
parser:name("rbx-screenshot")
parser:description("Capture a screenshot from Roblox Studio via rodeo exec")
parser:option("--cframe"):description("Luau CFrame expression")
parser:option("--fov"):description("Camera field of view"):convert(tonumber)
parser:option("-o --output"):description("Copy screenshot to this path")
parser:option("--settle"):description("Settle time in seconds"):convert(tonumber)
parser:option("--focus"):description("Luau CFrame expression for camera focus")
parser:option("--skew"):description("Luau CFrame expression applied to camera each frame")

local args = parser:parse(process.args)

local function parseReturnFile(filePath: string): { [string]: string | number }
	local text = fs.readFile(filePath)
	local result: { [string]: string | number } = {}

	for line in string.gmatch(text, "[^\r\n]+") do
		local strKey, strVal = string.match(line, '^\t%[?"?(%w+)"?%]?%s*=%s*"([^"]*)",?$')
		if strKey then
			result[strKey] = strVal
			continue
		end

		local numKey, numVal = string.match(line, '^\t%[?"?(%w+)"?%]?%s*=%s*([%d%.]+),?$')
		if numKey then
			result[numKey] = tonumber(numVal) :: number
		end
	end

	return result
end

local function findClosestFile(files: { string }, timestampMs: number): (string, number)
	local bestFile = files[1]
	local bestDelta = math.huge

	for _, file in files do
		local filePath = `{CAPTURE_DIR}/{file}`
		local meta = fs.metadata(filePath)
		if meta.exists then
			local mtimeMs = meta.modifiedAt.unixTimestampMillis
			local delta = math.abs(mtimeMs - timestampMs)
			if delta < bestDelta then
				bestDelta = delta
				bestFile = file
			end
		end
	end

	return bestFile, bestDelta
end

-- Build rodeo exec args with positional arguments (cframe, fov, settle)
local tmpDir = process.env.TMPDIR or "/tmp"
local returnFile = `{tmpDir}/rbx-screenshot-{os.clock()}.luau`

process.exec("rodeo", {
	"exec",
	"-s",
	_G.CAPTURE_SOURCE,
	"--return",
	returnFile,
	"--",
	args.cframe or "",
	tostring(args.fov or ""),
	tostring(args.settle or ""),
	args.focus or "",
	args.skew or "",
}, { stdio = "forward" })

-- Parse return file
local meta = parseReturnFile(returnFile)
fs.removeFile(returnFile)

local timestamp = meta.timestamp :: number

-- Find the captured file by timestamp
local allFiles: { string } = {}
for _, entry in fs.readDir(CAPTURE_DIR) do
	if string.sub(entry, 1, 4) == "wob-" then
		table.insert(allFiles, entry)
	end
end

table.sort(allFiles, function(a, b)
	local numA = tonumber(string.match(a, "wob%-(%d+)")) or 0
	local numB = tonumber(string.match(b, "wob%-(%d+)")) or 0
	return numA < numB
end)

if #allFiles == 0 then
	log.error(`Screenshot file not found in {CAPTURE_DIR}`)
	process.exit(1)
end

local closestFile, deltaMs = findClosestFile(allFiles, timestamp)
local sourcePath = `{CAPTURE_DIR}/{closestFile}`
log.info(`Closest file: {closestFile} (delta {string.format("%.0f", deltaMs)}ms)`)

if deltaMs > 5000 then
	log.warn(`Closest file mtime differs by {string.format("%.1f", deltaMs / 1000)}s`)
end

-- Copy to output (default: .rodeo-screenshots/<wob-filename>)
local outputPath = args.output or `{DEFAULT_OUTPUT_DIR}/{closestFile}.png`

local parentDir = string.match(outputPath, "^(.+)/[^/]+$")
if parentDir and not fs.isDir(parentDir) then
	fs.writeDir(parentDir)
end

fs.copy(sourcePath, outputPath, true)
log.success(outputPath)
