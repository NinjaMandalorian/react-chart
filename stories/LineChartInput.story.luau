local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local react_chart = require(ReplicatedStorage.Packages["react-chart"])

local e = React.createElement

local DEFAULT_JSON = "0, 0.5, 1, 0.5, 0, -0.5, -1, -0.5"

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
	controls = {},
	story = function()
		local jsonText, setJsonText = React.useState(DEFAULT_JSON)
		local data, setData = React.useState(decodeSeriesJson("[" .. DEFAULT_JSON .. "]") or { 0 })

		local function applyJson(text)
			setJsonText(text)

			local decoded = decodeSeriesJson("[" .. text .. "]")
			if decoded then
				setData(decoded)
			end
		end

		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			JsonInput = e("Frame", {
				Size = UDim2.fromScale(1, 0.1),
				BackgroundTransparency = 1,
			}, {
				Input = e("TextBox", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(28, 28, 32),
					TextColor3 = Color3.fromRGB(245, 245, 245),
					PlaceholderText = "Enter JSON array",
					Text = jsonText,
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					[React.Event.FocusLost] = function(rbx)
						applyJson(rbx.Text)
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
				}),
			}),
		})
	end,
}

return story