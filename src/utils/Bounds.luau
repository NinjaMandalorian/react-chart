local Bounds = {}

local function flattenNumber(value: number, round: boolean): number
	local exponent = math.floor(math.log10(value))
	local fraction = value / (10 ^ exponent)

	local niceFraction

	if round then
		if fraction < 1.5 then
			niceFraction = 1
		elseif fraction < 3 then
			niceFraction = 2
		elseif fraction < 7 then
			niceFraction = 5
		else
			niceFraction = 10
		end
	else
		if fraction <= 1 then
			niceFraction = 1
		elseif fraction <= 2 then
			niceFraction = 2
		elseif fraction <= 5 then
			niceFraction = 5
		else
			niceFraction = 10
		end
	end

	return niceFraction * (10 ^ exponent)
end

function Bounds.generateAxisTicks(bounds, ticks: number?)
	local targetTicks = ticks or 6

	local minY = bounds.YLower
	local maxY = bounds.YUpper

	if minY == maxY then
		minY -= 1
		maxY += 1
	end

	local range = flattenNumber(maxY - minY, false)

	local roughStep = range / (targetTicks - 1)
	local step = flattenNumber(roughStep, true)

	local niceMin = math.floor(minY / step) * step
	local niceMax = math.ceil(maxY / step) * step

	local tickArray = {}

	local v = niceMin
	while v <= niceMax + (step * 0.5) do
		table.insert(tickArray, v)
		v += step
	end

	return {
		ticks = tickArray,
		min = niceMin,
		max = niceMax,
		step = step,
	}
end

return Bounds