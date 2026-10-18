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
		TextSize = tokens.text["text-base"],
	},
}

return PROPERTY_DEFAULTS
