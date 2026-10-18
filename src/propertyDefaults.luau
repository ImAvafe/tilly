local tokens = require("./tokens")

const PROPERTY_DEFAULTS: { [string]: { [string]: any } } = {
	UIListLayout = {
		SortOrder = Enum.SortOrder.LayoutOrder,
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	},
	GuiObject = {
		AutomaticSize = Enum.AutomaticSize.XY,
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
	TextBox = {
		FontFace = Font.new(tokens.all["font-sans"], tokens.all["font-weight-normal"]),
		TextSize = tokens.all["text-base"],
		TextWrapped = tokens.all["text-wrapped-wrap"],
		TextXAlignment = tokens.all["text-align-left"],
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = tokens.all["text-base--line-height"],
		ClearTextOnFocus = false,
	},
}

return PROPERTY_DEFAULTS
