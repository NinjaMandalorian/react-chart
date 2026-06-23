local Types = require(script.Parent.Parent.Types)

type Theme = Types.Theme

-- Themes

local DARK_THEME: Theme = {
	Name = "Dark",
	Background = Color3.fromRGB(26, 28, 34),
	Surface = Color3.fromRGB(35, 38, 46),
	PlotBackground = Color3.fromRGB(29, 32, 39),
	Text = Color3.fromRGB(232, 236, 244),
	Grid = Color3.fromRGB(58, 64, 78),
	Accent = Color3.fromRGB(104, 171, 255),
}

-- Color overrides
local COLOR_OVERRIDES = {
	RGB = { Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1) },
}

local Theme = {
	DEFAULT = DARK_THEME,
	COLOR_OVERRIDES = COLOR_OVERRIDES,
}
local function hashString(str: string): number
	local hash = 2166136261 -- FNV offset basis

	for i = 1, #str do
		hash = bit32.bxor(hash, str:byte(i))
		hash = (hash * 16777619) % 2 ^ 32
	end

	return hash
end

local function keyToColor(name: string, isDark: boolean): Color3
	local hash = hashString(name)
	local hue = (hash % 360) / 360
	return Color3.fromHSV(hue, isDark and 0.65 or 0.80, isDark and 0.85 or 0.75)
end

function Theme.isDark(theme: Theme): boolean
	local _, _, v = theme.Background and theme.Background:ToHSV() or 0, 0, 0
	return v < 0.25
end

function Theme.reconcileTheme(theme: Theme?): Theme
	if theme == nil then
		return DARK_THEME
	end

	local newTheme = table.clone(theme)
	for key, value in pairs(DARK_THEME) do
		newTheme[key] = newTheme[key] or value
	end

	return newTheme
end

function Theme.getSeriesColors(theme: Theme, seriesNames: { string }): { [string]: Color3 }
	local colors = {}
	local override = theme.SeriesOverride
	if override then
		for idx, name in ipairs(seriesNames) do
			colors[name] = override[((idx - 1) % #override) + 1]
		end
	end

	local isDark = Theme.isDark(theme)

	for _, name in ipairs(seriesNames) do
		colors[name] = keyToColor(name, isDark)
	end

	return colors
end

return Theme
