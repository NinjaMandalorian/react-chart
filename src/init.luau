local Types = require(script.Types)
local LineGraph = require(script.graphs.LineGraph)
local Theme = require(script.utils.Theme)
export type SeriesData = { number }
export type SeriesMap = { [string]: SeriesData }

export type Theme = Types.Theme

local reactChart = {
	DEFAULT_THEME = Theme.DEFAULT,
	LineGraph = LineGraph,
}

return reactChart