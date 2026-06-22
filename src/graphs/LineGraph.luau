local src = script.Parent.Parent
local React = require(src.React)

local Types = require(src.Types)
local Theme = require(src.utils.Theme)
local Bounds = require(src.utils.Bounds)

local e = React.createElement

local isArray = function(t)
	return typeof(t) == "table" and t[1] ~= nil
end

local function normalize(value, min, max, lower, upper)
	return lower + ((value - min) * (upper - lower)) / (max - min)
end

type LineChartPoint = {
	X: number,
	Y: number,
}

type LineChartSeries = {
	Color: Color3,
	Points: { LineChartPoint },
}
type LineChartBounds = {
	XLower: number,
	XUpper: number,
	YLower: number,
	YUpper: number,
}
type LineChartSeriesMap = {
	Bounds: LineChartBounds,
	Dataset: { [string]: LineChartSeries },
}

local function prepareSeriesMap(data): Types.SeriesMap
	if isArray(data) and typeof(data[1]) == "number" then
		local series = {}
		for idx, value in ipairs(data) do
			table.insert(series, {
				X = idx,
				Y = value,
			})
		end
		return { Series = series }
	elseif isArray(data) and data[1] == "table" then
		return { Series = data }
	elseif not isArray(data) then
		return data
	else
		error("Not a valid series map")
	end
end

local function prepareChartData(data: Types.SeriesMap, theme: Types.Theme): LineChartSeriesMap
	local minX, maxX, minY, maxY = 0, 1, 0, 1

	local seriesNames = {}
	for name, _ in pairs(data) do
		table.insert(seriesNames, name)
	end
	local colors = Theme.getSeriesColors(theme, seriesNames)

	local dataset = {}
	for seriesName, seriesData in pairs(data) do
		local points = {}
		for idx, value in ipairs(seriesData) do
			local point = {
				X = value.X or idx,
				Y = value.Y,
			}

			minX = math.min(minX, point.X)
			minY = math.min(minY, point.Y)
			maxX = math.max(maxX, point.X)
			maxY = math.max(maxY, point.Y)

			table.insert(points, point)
		end
		table.sort(points, function(a, b)
			return a.X < b.X
		end)
		dataset[seriesName] = {
			Color = colors[seriesName],
			Points = points,
		}
	end

	return {
		Bounds = {
			XLower = minX,
			XUpper = maxX,
			YLower = minY,
			YUpper = maxY,
		},
		Dataset = dataset,
	}
end

local function buildSeries(data: LineChartSeries, plotSize: Vector2, bounds: LineChartBounds)
	local normalisedPoints : { LineChartPoint } = {}
	for _, point in ipairs(data.Points) do
		table.insert(normalisedPoints, {
			X = normalize(point.X, bounds.XLower, bounds.XUpper, 0, 1),
			Y = 1 - normalize(point.Y, bounds.YLower, bounds.YUpper, 0, 1),
		})
	end

	local points = {}
	local segments = {}

	for pIdx = 1, #normalisedPoints do
		local prevPoint = normalisedPoints[pIdx - 1]
		local point = normalisedPoints[pIdx]
		local pointX = point.X
		local pointY = point.Y

		table.insert(
			points,
			e("Frame", {
				BackgroundColor3 = data.Color,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(pointX, pointY),
				Size = UDim2.fromOffset(8, 8),
				ZIndex = 5,
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				e("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Transparency = 0.35,
					Thickness = 1,
				}),
			})
		)

		if prevPoint then
			local prevX = prevPoint.X * plotSize.X
			local prevY = prevPoint.Y * plotSize.Y
			local nextX = point.X * plotSize.X
			local nextY = point.Y * plotSize.Y
			local delta = Vector2.new(nextX - prevX, nextY - prevY)
			local length = delta.Magnitude

			table.insert(segments, e("Frame", {
				BackgroundColor3 = data.Color,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset((prevX + nextX) / 2, (prevY + nextY) / 2),
				Rotation = math.deg(math.atan2(delta.Y, delta.X)),
				Size = UDim2.fromOffset(length, 2),
				ZIndex = 4,
			}))
		end
	end

	return points, segments
end

function LineGraph(props: Types.LineGraphProps)
	-- State
	local theme = Theme.reconcileTheme(props.Theme)
	local plotRef = React.useRef(nil :: Frame?)
	local plotSize, setPlotSize = React.useState(Vector2.new(0, 0))

	local chartData: LineChartSeriesMap = React.useMemo(function()
		local seriesMap = prepareSeriesMap(props.Data)
		return prepareChartData(seriesMap, theme)
	end, { props.Data })

	React.useEffect(function()
		local pFrame = plotRef.current
		if not pFrame then
			return nil
		end

		local function updateSize()
			setPlotSize(pFrame.AbsoluteSize)
		end

		updateSize()
		local connection = pFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
		return function()
			connection:Disconnect()
		end
	end, {plotRef.current})


	local tickData = Bounds.generateAxisTicks(chartData.Bounds, 6)
	chartData.Bounds.YLower = tickData.min
	chartData.Bounds.YUpper = tickData.max

	-- Rendering
	local seriesElements = {}
	for _, series in pairs(chartData.Dataset) do
		local points, segments = buildSeries(series, plotSize, chartData.Bounds)
		for _, point in ipairs(points) do
			table.insert(seriesElements, point)
		end
		for _, segment in ipairs(segments) do
			table.insert(seriesElements, segment)
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		SeriesPlot = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ref = plotRef,
		}, e(React.Fragment, nil, seriesElements))
	})
end

return LineGraph
