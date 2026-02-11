local CaptureService = game:GetService("CaptureService")
local RunService = game:GetService("RunService")

return function(args: { string }?)
	local cframeStr: string? = if args and args[1] ~= "" then args[1] else nil
	local fov: number? = if args and args[2] ~= "" then tonumber(args[2]) else nil
	local settle: number = if args and args[3] ~= "" then (tonumber(args[3]) or 0) else 0
	local focusStr: string? = if args and args[4] ~= "" then args[4] else nil
	local skewStr: string? = if args and args[5] ~= "" then args[5] else nil

	local camera = workspace.CurrentCamera
	local cframe: CFrame? = if cframeStr then (loadstring("return " .. cframeStr) :: any)() else nil
	local focus: CFrame? = if focusStr then (loadstring("return " .. focusStr) :: any)() else nil
	local skew: CFrame? = if skewStr then (loadstring("return " .. skewStr) :: any)() else nil
	local focusConn: RBXScriptConnection? = nil

	if cframe or fov or focus or skew or settle > 0 then
		if cframe then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = cframe
		end
		if fov then
			camera.FieldOfView = fov
		end

		focusConn = RunService.RenderStepped:Connect(function()
			if cframe then
				camera.CFrame = cframe
			end
			if skew then
				camera.CFrame *= skew
			end
			if focus then
				camera.Focus = focus
			elseif cframe then
				camera.Focus = CFrame.new(cframe.Position + cframe.LookVector * 100)
			end
			if fov then
				camera.FieldOfView = fov
			end
		end)

		task.wait(settle)
	end

	local content_id: string? = nil
	CaptureService:CaptureScreenshot(function(id: string)
		content_id = id
	end)
	while not content_id do
		task.wait()
	end

	if focusConn then
		focusConn:Disconnect()
	end

	return {
		timestamp = DateTime.now().UnixTimestampMillis,
	}
end
