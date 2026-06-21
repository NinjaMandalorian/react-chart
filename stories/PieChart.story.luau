--[[
	Simple piechart demonstration
	Built off of pyseph's PacketProfiler CircleArcs (https://github.com/Pyseph/PacketProfiler)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local e = React.createElement

local CIRCLE_IMAGE = "rbxassetid://3587367081"

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function safeNumber(v)
	local n = tonumber(v)
	return (n and n > 0) and n or 0
end

local story = {
	react = React,
	reactRoblox = ReactRoblox,

	controls = {
		speed = 1,
	},
	story = function(props)

		local red, setRed = React.useState("5")
		local blue, setBlue = React.useState("5")
		local green, setGreen = React.useState("5")
		local yellow, setYellow = React.useState("5")
		local cap, setCap = React.useState("100")

		local alpha, setAlpha = React.useState(0)

		React.useEffect(function()
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				setAlpha(function(old)
					old = old or 0
					return math.min(old + dt * (props.controls and props.controls.speed or 1), 1)
				end)
			end)

			return function()
				conn:Disconnect()
			end
		end, { props.controls.speed })

		local function buildArcs()
			local r = safeNumber(red)
			local b = safeNumber(blue)
			local g = safeNumber(green)
			local y = safeNumber(yellow)

			local total = r + b + g + y
			if total == 0 then
				return {}
			end

			local capPercent = math.clamp(tonumber(cap) or 100, 0, 100) / 100

			local function scaled(v)
				return (v / total) * 100 * capPercent
			end

			return {
				{Name = "Red", Percent = scaled(r), Color = Color3.fromRGB(255, 80, 80)},
				{Name = "Blue", Percent = scaled(b), Color = Color3.fromRGB(80, 160, 255)},
				{Name = "Green", Percent = scaled(g), Color = Color3.fromRGB(80, 255, 120)},
				{Name = "Yellow", Percent = scaled(y), Color = Color3.fromRGB(255, 220, 80)},
			}
		end

		local function createArc(side, visiblePercent, color, z)
			local rotation

			if side == "Left" then
				local p = lerp(0, visiblePercent, math.clamp(alpha * 2, 0, 1))
				rotation = -3.6 * p + 180
			else
				local p = lerp(0, visiblePercent - 50, math.clamp(alpha * 2 - 1, 0, 1))
				rotation = lerp(0, -180, p / 100) * 2
			end

			return e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = CIRCLE_IMAGE,
				ImageColor3 = color,
				Size = UDim2.fromScale(2, 1),
				Position = UDim2.fromScale(side == "Left" and 0 or -1, 0),
				ZIndex = z,
			}, {
				e("UIGradient", {
					Rotation = rotation,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(side == "Left" and 0.498 or 0.5, 0),
						NumberSequenceKeypoint.new(side == "Left" and 0.499 or 0.501, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			})
		end

		local arcs = buildArcs()

		local start = 0
		local left, right = {}, {}

		for i, arc in ipairs(arcs) do
			local endP = math.min(start + arc.Percent, 100)
			local z = #arcs - i + 1

			if endP > 50 and start <= 50 then
				left["cross_" .. i] = createArc("Left", 50, arc.Color, z)
			end

			local side = endP > 50 and "Right" or "Left"
			local el = createArc(side, endP, arc.Color, z)

			if side == "Left" then
				left[tostring(i)] = el
			else
				right[tostring(i)] = el
			end

			start += arc.Percent
		end

		return e("Frame", {
			Size = UDim2.fromOffset(650, 320),
			BackgroundTransparency = 1,
		}, {

			Chart = e("Frame", {
				Size = UDim2.fromOffset(300, 300),
				BackgroundTransparency = 1,
			}, {
				Left = e("Frame", {
					Size = UDim2.fromScale(0.5, 1),
					ClipsDescendants = true,
					BackgroundTransparency = 1,
				}, left),

				Right = e("Frame", {
					Size = UDim2.fromScale(0.5, 1),
					Position = UDim2.fromScale(1, 0),
					AnchorPoint = Vector2.new(1, 0),
					ClipsDescendants = true,
					BackgroundTransparency = 1,
				}, right),
			}),

			Controls = e("Frame", {
				Size = UDim2.fromOffset(250, 300),
				Position = UDim2.fromOffset(320, 0),
				BackgroundTransparency = 1,
			}, {

				Red = e("TextBox", {
					Text = red,
					PlaceholderText = "Red",
					BackgroundColor3 = Color3.new(0.819608, 0.313725, 0.313725),
					Size = UDim2.fromOffset(200, 30),
					[React.Event.FocusLost] = function(rbx) setRed(rbx.Text) end,
				}),

				Blue = e("TextBox", {
					Text = blue,
					PlaceholderText = "Blue",
					BackgroundColor3 = Color3.new(0.313725, 0.47451, 0.819608),
					Position = UDim2.fromOffset(0, 40),
					Size = UDim2.fromOffset(200, 30),
					[React.Event.FocusLost] = function(rbx) setBlue(rbx.Text) end,
				}),

				Green = e("TextBox", {
					Text = green,
					PlaceholderText = "Green",
					BackgroundColor3 = Color3.new(0.313725, 0.819608, 0.341176),
					Position = UDim2.fromOffset(0, 80),
					Size = UDim2.fromOffset(200, 30),
					[React.Event.FocusLost] = function(rbx) setGreen(rbx.Text) end,
				}),

				Yellow = e("TextBox", {
					Text = yellow,
					PlaceholderText = "Yellow",
					BackgroundColor3 = Color3.new(0.819608, 0.768627, 0.313725),
					Position = UDim2.fromOffset(0, 120),
					Size = UDim2.fromOffset(200, 30),
					[React.Event.FocusLost] = function(rbx) setYellow(rbx.Text) end,
				}),

				Cap = e("TextBox", {
					Text = cap,
					PlaceholderText = "Loaded % (0-100)",
					Position = UDim2.fromOffset(0, 160),
					Size = UDim2.fromOffset(200, 30),
					[React.Event.FocusLost] = function(rbx)
						setCap(rbx.Text)
					end,
				}),
			}),
		})
	end,
}

return story