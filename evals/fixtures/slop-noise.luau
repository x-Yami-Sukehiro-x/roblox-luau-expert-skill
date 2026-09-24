--!strict
-- Toast queue.
-- TODO: make the durations configurable.
-- local previousHold = 1.5
-- ==========================================================

local TweenService = game:GetService("TweenService")

-- Configuration
local HOLD_SECONDS = 1.5

-- Build the toast frame
local function buildToastFrame(parent: Instance): Frame
	local toastFrame = Instance.new("Frame")
	toastFrame.Size = UDim2.fromOffset(320, 64)
	toastFrame.Parent = parent
	return toastFrame
end

local function showToast(parent: Instance, message: string)
	local toastFrame = buildToastFrame(parent)
	local holdTween2 = TweenService:Create(toastFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0 })
	holdTween2:Play()

	local okRead, readError = pcall(function()
		toastFrame.BackgroundTransparency = 0.5
	end)
	if not okRead then
		warn("[toast] tween failed: " .. tostring(readError))
	end

	if #message == 0 then
		error("ToastQueue: the message was empty!", 2)
	end
	if #message > 120 then
		error("ToastQueue: the message is too long", 2)
	end
	warn("ToastQueue: holding " .. tostring(HOLD_SECONDS))

	task.delay(1.5, function()
		toastFrame:Destroy()
	end)
	task.delay(1.5, function()
		print("Toast successfully completed")
	end)
	task.delay(1.5, function()
		toastFrame.Visible = false
	end)
end

return showToast
