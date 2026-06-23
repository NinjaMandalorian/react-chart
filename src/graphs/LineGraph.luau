local src = script.Parent.Parent
local React = require(src.React)

local Types = require(src.Types)
local Theme = require(src.utils.Theme)
local Bounds = require(src.utils.Bounds)

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
	HasXAxis: boolean,
}
local e = React.createElement

local AXIS_THICKNESS = 0.1
local VERTICAL_PADDING = 0.03

local isArray = function(t)
	return typeof(t) == "table" and t[1] ~= nil
end

local function round(value: number, decimals: number) : number
	local factor = 10 ^ decimals
	return math.round(value * factor) / factor
end

local function normalize(value, min, max, lower, upper)
	return lower + ((value - min) * (upper - lower)) / (max - min)
end

local function normalizeWithPadding(value, min, max)
	return normalize(value, min, max, VERTICAL_PADDING, 1 - VERTICAL_PADDING)
end

local function formatTickValue(value: number, format : string?): string
	if math.abs(value) < 1e-6 then
		value = 0
	end

	return string.format(format or "%g", value)
end

local function getLowestCommonFormat(numbers : { number }) : string
	local leftSize, rightSize = 1,0

	for _, value in ipairs(numbers) do
		if math.abs(value) > 1e6 then
			return "%G"
		end

		local left, right = math.modf(value)
		local leftLen = #tostring(round(left, 6))
		local rightLen = #tostring(round(math.abs(right), 6)) - 2
		-- print(string.format("%5g -> (%4g & %4g) -> %d & %d", value, left, right, leftLen, rightLen))
		leftSize = math.max(leftSize, leftLen)
		rightSize = math.max(rightSize, rightLen)
	end

	return `%0{leftSize + rightSize}.{rightSize}f`
end

local function prepareSeriesMap(data): (Types.SeriesMap, boolean)
	
	local function convertPoint(point : any, idx: number): (Types.SeriesPoint, boolean)
		if typeof(point) == "number" then
			return {
				X = idx,
				Y = point
			}, false
		elseif typeof(point) == "table" and point.Y then
			return {
				X = point.X or idx,
				Y = point.Y
			}, point.X ~= nil
		else
			error(`Invalid point to convert: {point}`)
		end
	end

	if isArray(data) and typeof(data[1]) == "number" then
		local series = {}
		for idx, value in ipairs(data) do
			local point = convertPoint(value, idx)
			table.insert(series, point)
		end
		return { Series = series }, false
	elseif isArray(data) and typeof(data[1]) == "table" then
		local hasXAxis = false
		local output = {}
		for sIdx, series in ipairs(data) do
			local oSeries = {}
			for idx, value in ipairs(series) do
				local point, pointHasX = convertPoint(value, idx)
				hasXAxis = hasXAxis and pointHasX
				table.insert(oSeries, point)
			end
			output["Series" .. sIdx] = oSeries
		end

		return { Series = data }, hasXAxis
	elseif not isArray(data) then
		local hasXAxis = false
		local output = {}
		for seriesName, seriesData in pairs(data) do
			local oSeries = {}
			for idx, value in ipairs(seriesData) do
				local point, pointHasX = convertPoint(value, idx)
				hasXAxis = hasXAxis and pointHasX
				table.insert(oSeries, point)
			end
			output[seriesName] = oSeries
		end

		return output, hasXAxis
	else
		error("Not a valid series map")
	end
end

local function prepareChartData(data: Types.SeriesMap, theme: Types.Theme, hasXAxis: boolean): LineChartSeriesMap
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
		HasXAxis = hasXAxis,
	}
end

local function buildAxisTicks(axis: "X" | "Y", ticks, bounds: LineChartBounds, theme: Types.Theme)
	local isYAxis = axis == "Y"

	local elements = {
		AxisLine = e("Frame", {
			BackgroundColor3 = theme.Grid,
			BorderSizePixel = 0,
			AnchorPoint = isYAxis and Vector2.new(1, 0) or nil,
			Position = isYAxis and UDim2.fromScale(1, 0) or UDim2.fromScale(0, 0),
			Size = isYAxis and UDim2.fromOffset(1, 0) or UDim2.fromOffset(0, 1),
			ZIndex = 2,
		}),
	}

	local tickFormat = getLowestCommonFormat(ticks.ticks)

	for idx, tickVal in ipairs(ticks.ticks) do
		local tickPosition = isYAxis
			and (1 - normalizeWithPadding(tickVal, bounds.YLower, bounds.YUpper))
			or normalize(tickVal, bounds.XLower, bounds.XUpper, 0, 1)

		elements["TickLine" .. idx] = e("Frame", {
			BackgroundColor3 = isYAxis and theme.Text or theme.Grid,
			BorderSizePixel = 0,
			AnchorPoint = isYAxis and Vector2.new(1, 0.5) or Vector2.new(0.5, 0),
			Position = isYAxis and UDim2.fromScale(1, tickPosition) or UDim2.fromScale(tickPosition, 0),
			Size = isYAxis and UDim2.fromOffset(6, 1) or UDim2.fromOffset(1, 6),
			ZIndex = 2,
		})

		elements["TickLabel" .. idx] = e("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = isYAxis and Vector2.new(1, 0.5) or Vector2.new(0.5, 0),
			Position = isYAxis and UDim2.fromScale(0.9, tickPosition) or UDim2.fromScale(tickPosition, 0.16),
			Size = isYAxis and UDim2.fromScale(0.4, 0.18) or UDim2.fromScale(0.2, 0.72),
			Text = formatTickValue(tickVal, tickFormat),
			TextColor3 = theme.Text,
			TextScaled = true,
			TextWrapped = false,
			TextXAlignment = isYAxis and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center,
			TextYAlignment = isYAxis and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top,
			ZIndex = 3,
		}, {
			SizeLimit = e("UITextSizeConstraint", {
				-- MaxTextSize = 30,
			})
		})
	end

	return elements
end

local function buildSeries(data: LineChartSeries, plotSize: Vector2, bounds: LineChartBounds)
	local normalisedPoints : { LineChartPoint } = {}
	for _, point in ipairs(data.Points) do
		table.insert(normalisedPoints, {
			X = normalize(point.X, bounds.XLower, bounds.XUpper, 0, 1),
			Y = 1 - normalizeWithPadding(point.Y, bounds.YLower, bounds.YUpper),
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
		local seriesMap, hasXAxis = prepareSeriesMap(props.Data)
		return prepareChartData(seriesMap, theme, hasXAxis)
	end, { props.Data, props.Theme })

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

	local xTickData = nil
	if chartData.HasXAxis then
		xTickData = Bounds.generateAxisTicks({
			YLower = chartData.Bounds.XLower,
			YUpper = chartData.Bounds.XUpper,
		}, 6)
		chartData.Bounds.XLower = xTickData.min
		chartData.Bounds.XUpper = xTickData.max
	end

	local topInset = 0.1 + VERTICAL_PADDING
	local bottomInset = chartData.HasXAxis and AXIS_THICKNESS or 0
	local plotHeight = 1 - topInset - bottomInset - VERTICAL_PADDING
	local plotWidth = 1 - AXIS_THICKNESS

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
		BackgroundTransparency = theme.TransparentBackground and 1 or 0,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
	}, {
		
		GraphYAxis = e("Frame", {
			Size = UDim2.fromScale(AXIS_THICKNESS, plotHeight),
			Position = UDim2.fromScale(0, topInset),
			BackgroundTransparency = 1,
		}, buildAxisTicks("Y", tickData, chartData.Bounds, theme)),
		GraphXAxis = chartData.HasXAxis and e("Frame", {
			Size = UDim2.fromScale(plotWidth, AXIS_THICKNESS),
			Position = UDim2.fromScale(AXIS_THICKNESS, topInset + plotHeight),
			BackgroundTransparency = 1,
		}, buildAxisTicks("X", xTickData, chartData.Bounds, theme)) or nil,
		GraphPlot = e("Frame", {
			Position = UDim2.fromScale(AXIS_THICKNESS, topInset),
			Size = UDim2.fromScale(plotWidth, plotHeight),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.PlotBackground,
			BackgroundTransparency = theme.TransparentBackground and 1 or 0,
			ref = plotRef,
		}, e(React.Fragment, nil, seriesElements))
	})
end

return LineGraph
