local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local react_chart = require(ReplicatedStorage.Packages["react-chart"])

local e = React.createElement

local function normalizeSeriesJson(jsonText)
	local trimmed = jsonText:match("^%s*(.-)%s*$")

	if trimmed:sub(1, 1) == "[" and trimmed:sub(-1) == "]" then
		return trimmed
	end

	if trimmed:sub(1, 1) == "{" and trimmed:sub(-1) == "}" then
		return trimmed
	end

	return "[" .. trimmed .. "]"
end

local function decodeSeriesJson(jsonText)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(jsonText)
	end)

	if ok and typeof(decoded) == "table" then
		return decoded
	end

	return nil
end

local story = {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		json = "0, 0.5, 1, 0.5, 0, -0.5, -1, -0.5",
		TransparentBackground = false,
		GradualLoad = false,
	},
	story = function(props)
		local jsonText, setJsonText = React.useState("")
		local data, setData = React.useState({})
		local transparent, setTransparent = React.useState(props.controls.TransparentBackground)
		local gradual, setGradual = React.useState(false)
		
		React.useEffect(function()
			setGradual(props.controls.GradualLoad)
		end, {props.controls.GradualLoad})

		React.useEffect(function()
			setTransparent(props.controls.TransparentBackground)
		end, {props.controls.TransparentBackground})

		React.useEffect(function()
			if props.controls.GradualLoad then
				setJsonText("")
			end
			setJsonText(props.controls.json)
		end, {props.controls.json, props.controls.GradualLoad})

		React.useEffect(function()
			local decoded = decodeSeriesJson(normalizeSeriesJson(jsonText))
			if decoded then
				if not gradual then
					setData(decoded)
					return nil
				end
				if decoded[1] and typeof(decoded[1]) == "number" then
					decoded = {Series = decoded}
				end
				
				local stream = {}
				local duration = 5
				local startTime = os.clock()
				
				local maxLen = 0
				for _, series in pairs(decoded) do
					maxLen = math.max(maxLen, #series)
				end

				for i = 1, maxLen do
					for name, series in pairs(decoded) do
						local point = series[i]
						if point then
							table.insert(stream, {
								Series = name,
								Point = point,
							})
						end
					end
				end

				local incremental = {}
				for name in pairs(decoded) do
					incremental[name] = {}
				end

				local index = 0
				local total = #stream

				local conn
				conn = RunService.Heartbeat:Connect(function()
					local elapsed = os.clock() - startTime
					local targetCount = math.clamp(math.floor((elapsed / duration) * total), 0, total)
					if targetCount <= index then
						return
					end
					print(index, targetCount)
					while index < targetCount do
						index += 1
						local item = stream[index]

						table.insert(incremental[item.Series], item.Point)
					end

					setData(table.clone(incremental))

					if index >= total then
						conn:Disconnect()
					end
				end)

				return function()
					if conn then
						conn:Disconnect()
					end
				end
			end
			return nil
		end, {jsonText, gradual})

		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			JsonInput = e("Frame", {
				Size = UDim2.fromScale(1, 0.1),
				BackgroundColor3 = Color3.fromRGB(28, 28, 32),
			}, {
				Input = e("TextBox", {
					AnchorPoint = Vector2.new(.5,0),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.fromScale(0.9, 1),
					TextColor3 = Color3.fromRGB(245, 245, 245),
					PlaceholderText = "Enter JSON array",
					Text = jsonText,
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextWrapped = true,
					[React.Event.FocusLost] = function(rbx)
						setJsonText(rbx.Text)
					end,
				}),
			}),

			Chart = e("Frame", {
				Position = UDim2.fromScale(0, 0.1),
				Size = UDim2.fromScale(1, 0.9),
				BackgroundTransparency = 1,
			}, {
				Graph = e(react_chart.LineGraph, {
					Data = data,
					Theme = {
						TransparentBackground = transparent,
						SeriesOverride = react_chart.ColorOverrides.RainbowDark,
					}
				}),
			}),
		})
	end,
}

return story