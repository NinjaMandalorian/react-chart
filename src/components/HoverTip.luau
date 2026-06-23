local React = require(script.Parent.Parent.React)

local e = React.createElement

local DEFAULT_BACKGROUND = Color3.fromRGB(33, 36, 44)
local DEFAULT_BORDER = Color3.fromRGB(84, 92, 108)
local DEFAULT_TEXT = Color3.fromRGB(243, 246, 250)

function HoverTip(props)
	local hovering, setHovering = React.useState(false)

	local hoverSize = props.HoverSize or UDim2.fromOffset(120, 60)
	local hoverPosition = props.Position
	local hoverAnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	local hoverZIndex = props.ZIndex or 1

	return e("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Position = hoverPosition,
		Size = hoverSize,
		AnchorPoint = hoverAnchorPoint,
		ZIndex = hoverZIndex,
		Active = true,
		[React.Event.MouseEnter] = function()
			setHovering(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovering(false)
		end,
	}, {
		Content = e(React.Fragment, nil, props.children),
		Tooltip = hovering and e("Frame", {
			BackgroundColor3 = props.BackgroundColor3 or DEFAULT_BACKGROUND,
			BorderColor3 = props.BorderColor3 or DEFAULT_BORDER,
			BorderSizePixel = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			ZIndex = hoverZIndex + 1,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				Font = Enum.Font.Gotham,
				Text = props.Text,
				TextColor3 = props.TextColor3 or DEFAULT_TEXT,
				TextSize = 12,
				TextWrapped = false,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = hoverZIndex + 2,
			}),
		}) or nil,
	})
end

return HoverTip