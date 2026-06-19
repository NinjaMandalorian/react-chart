local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local react_chart = require(ReplicatedStorage.Packages["react-chart"])

local e = React.createElement

local story = {
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		points = 60,
		speed = 1,
	},
	story = function(props)
		local pointCount = math.floor(props.controls.points)
		local movePeriod = props.controls.speed > 0 and (50 * props.controls.speed / pointCount) or 0
		movePeriod = math.max(movePeriod, 0.01)

		local data, setData = React.useState({})
		React.useEffect(function()
			local series = {}
			for i = 1, pointCount do
				table.insert(series, math.sin(math.rad(360 / pointCount * i)))
			end

			setData(series)
		end, {pointCount})

		React.useEffect(function()
			local elapsed = 0

			local conn = RunService.Heartbeat:Connect(function(dt)
				elapsed += dt

				if elapsed >= (0.1 / movePeriod) then
					elapsed = 0

					setData(function(prev)
						local newData = table.clone(prev)
						local first = table.remove(newData, 1)
						table.insert(newData, first)
						return newData
					end)
				end
			end)

			return function()
				conn:Disconnect()
			end
		end, {movePeriod})

		return e(react_chart.LineGraph, {
			Data = data
		}, {

		})
	end,
}

return story