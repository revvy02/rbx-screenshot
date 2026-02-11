local stdio = require("@lune/stdio")

local reset_color = stdio.color("reset")
local red_color = stdio.color("red")
local yellow_color = stdio.color("yellow")
local blue_color = stdio.color("blue")
local green_color = stdio.color("green")

local function write(msg: string, color: string, err: boolean): ()
	local out_str: string = color .. msg .. reset_color .. "\n"
	if err then
		stdio.ewrite(out_str)
	else
		stdio.write(out_str)
	end
end

return {
	error = function(msg: string): ()
		write(msg, red_color, true)
	end,
	warn = function(msg: string): ()
		write(msg, yellow_color, false)
	end,
	info = function(msg: string): ()
		write(msg, blue_color, false)
	end,
	success = function(msg: string): ()
		write(msg, green_color, false)
	end,
}
