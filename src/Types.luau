export type SeriesPoint = {
	X: number?,
	Y: number,
}
export type SeriesData = { SeriesPoint }
export type SeriesMap = { [string]: SeriesData }

export type Theme = {
	Name: string?,
	TransparentBackground: boolean?,
	Background: Color3?,
	Surface: Color3?,
	PlotBackground: Color3?,
	Text: Color3?,
	Grid: Color3?,
	Accent: Color3?,
	SeriesOverride: {Color3}?
}

export type LineGraphProps = {
	Data: SeriesMap | SeriesData | {number},
	Resolution: number?,
	BaselineZero: boolean?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Title: string?,
	Theme: Theme?,
}

return {}