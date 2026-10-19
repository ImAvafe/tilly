local tokens = require("./tokens")

const PROPERTY_DEFAULTS: { [string]: { [string]: any } } = {
	GuiObject = {
		AutomaticSize = Enum.AutomaticSize.XY,
		BorderSizePixel = 0,
		BorderMode = Enum.BorderMode.Inset,
		BackgroundTransparency = 1,
	},
	UIListLayout = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
	},
	GuiButton = {
		AutoButtonColor = false,
	},
	TextLabel = {
		FontFace = Font.new(tokens.all["font-sans"], tokens.all["font-weight-normal"]),
		TextSize = tokens.all["text-base"],
		TextWrapped = tokens.all["text-wrapped-wrap"],
		TextXAlignment = tokens.all["text-align-left"],
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = tokens.all["text-base--line-height"],
	},
	TextButton = {
		FontFace = Font.new(tokens.all["font-sans"], tokens.all["font-weight-normal"]),
		TextSize = tokens.all["text-base"],
		TextWrapped = tokens.all["text-wrapped-wrap"],
		TextXAlignment = tokens.all["text-align-left"],
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = tokens.all["text-base--line-height"],
	},
	TextBox = {
		FontFace = Font.new(tokens.all["font-sans"], tokens.all["font-weight-normal"]),
		TextSize = tokens.all["text-base"],
		TextWrapped = tokens.all["text-wrapped-wrap"],
		TextXAlignment = tokens.all["text-align-left"],
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = tokens.all["text-base--line-height"],
		ClearTextOnFocus = false,
	},
	ImageLabel = {
		ScaleType = Enum.ScaleType.Fit,
	},
	ImageButton = {
		ScaleType = Enum.ScaleType.Fit,
	},
}

return PROPERTY_DEFAULTS
