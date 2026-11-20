export type Pattern = {
	namespace: string,
	properties: { string },
	manualProperties: { [string]: any }?,
	pseudoInstance: string?,
	propertyComponent: string?, -- Sets only this component of the property, like X of a Size
	-- Properties set from `{namespace}-{value}--{subtoken}-1` tokens, or components from `{namespace}-{value}--{subtoken}`
	-- tokens when `propertyComponent` is set
	subtokens: { [string]: string }?,
}

const PATTERNS: { [string]: { Pattern } } = {
	-- Background utils
	["bg"] = {
		{
			namespace = "color",
			properties = { "BackgroundColor3" },
			manualProperties = {
				BackgroundTransparency = 0,
			},
		},
		{
			namespace = "object",
			properties = { "ScaleType" },
		},
	},
	["opacity"] = {
		{
			namespace = "opacity",
			properties = { "Transparency" },
		},
	},

	-- Text utils
	["text"] = {
		{
			namespace = "text",
			properties = { "TextSize" },
		},
		{
			namespace = "color",
			properties = { "TextColor3" },
		},
		{
			namespace = "text-align",
			properties = { "TextXAlignment" },
		},
		{
			namespace = "text-wrapped",
			properties = { "TextWrapped" },
		},
		{
			namespace = "text-truncate",
			properties = { "TextTruncate" },
		},
	},
	["font"] = {
		{
			namespace = "font",
			properties = { "FontFace" },
			propertyComponent = "Family",
		},
		{
			namespace = "font-weight",
			properties = { "FontFace" },
			propertyComponent = "Weight",
		},
	},
	["leading"] = {
		{
			namespace = "leading",
			properties = { "LineHeight" },
		},
	},

	-- Border utils
	["border"] = {
		{
			namespace = "border",
			properties = { "Thickness" },
			pseudoInstance = "UIStroke",
		},
		{
			namespace = "color",
			properties = { "Color" },
			pseudoInstance = "UIStroke",
		},
	},
	-- Shadow utils
	["shadow"] = {
		{
			namespace = "shadow",
			properties = { "Enabled" },
			pseudoInstance = "UIShadow",
			subtokens = {
				offset = "Offset",
				blur = "BlurRadius",
				spread = "Spread",
				color = "Color",
				transparency = "Transparency",
			},
		},
		{
			namespace = "color",
			properties = { "Color" },
			pseudoInstance = "UIShadow",
		},
	},

	-- Corner radius
	["rounded"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius", "TopRightRadius", "BottomRightRadius", "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-t"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius", "TopRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-r"] = {
		{
			namespace = "radius",
			properties = { "TopRightRadius", "BottomRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-b"] = {
		{
			namespace = "radius",
			properties = { "BottomRightRadius", "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-l"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius", "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-tl"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-tr"] = {
		{
			namespace = "radius",
			properties = { "TopRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-br"] = {
		{
			namespace = "radius",
			properties = { "BottomRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-bl"] = {
		{
			namespace = "radius",
			properties = { "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	-- Logical corners assume LTR
	["rounded-s"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius", "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-e"] = {
		{
			namespace = "radius",
			properties = { "TopRightRadius", "BottomRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-ss"] = {
		{
			namespace = "radius",
			properties = { "TopLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-se"] = {
		{
			namespace = "radius",
			properties = { "TopRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-ee"] = {
		{
			namespace = "radius",
			properties = { "BottomRightRadius" },
			pseudoInstance = "UICorner",
		},
	},
	["rounded-es"] = {
		{
			namespace = "radius",
			properties = { "BottomLeftRadius" },
			pseudoInstance = "UICorner",
		},
	},

	-- Spacing
	["p"] = {
		{
			namespace = "spacing",
			properties = { "PaddingTop", "PaddingRight", "PaddingBottom", "PaddingLeft" },
			pseudoInstance = "UIPadding",
		},
	},
	["px"] = {
		{
			namespace = "spacing",
			properties = { "PaddingLeft", "PaddingRight" },
			pseudoInstance = "UIPadding",
		},
	},
	["py"] = {
		{
			namespace = "spacing",
			properties = { "PaddingTop", "PaddingBottom" },
			pseudoInstance = "UIPadding",
		},
	},
	["pt"] = {
		{
			namespace = "spacing",
			properties = { "PaddingTop" },
			pseudoInstance = "UIPadding",
		},
	},
	["pr"] = {
		{
			namespace = "spacing",
			properties = { "PaddingRight" },
			pseudoInstance = "UIPadding",
		},
	},
	["pb"] = {
		{
			namespace = "spacing",
			properties = { "PaddingBottom" },
			pseudoInstance = "UIPadding",
		},
	},
	["pl"] = {
		{
			namespace = "spacing",
			properties = { "PaddingLeft" },
			pseudoInstance = "UIPadding",
		},
	},
	-- Logical padding assumes LTR
	["ps"] = {
		{
			namespace = "spacing",
			properties = { "PaddingLeft" },
			pseudoInstance = "UIPadding",
		},
	},
	["pe"] = {
		{
			namespace = "spacing",
			properties = { "PaddingRight" },
			pseudoInstance = "UIPadding",
		},
	},
	["pbs"] = {
		{
			namespace = "spacing",
			properties = { "PaddingTop" },
			pseudoInstance = "UIPadding",
		},
	},
	["pbe"] = {
		{
			namespace = "spacing",
			properties = { "PaddingBottom" },
			pseudoInstance = "UIPadding",
		},
	},
	["gap"] = {
		{
			namespace = "spacing",
			properties = { "Padding" },
			pseudoInstance = "UIListLayout",
		},
	},
	["gap-x"] = {
		{
			namespace = "spacing",
			properties = { "Padding" },
			pseudoInstance = "UIListLayout",
		},
	},
	["gap-y"] = {
		{
			namespace = "spacing",
			properties = { "Padding" },
			pseudoInstance = "UIListLayout",
		},
	},

	-- Sizing utils
	["w"] = {
		{
			namespace = "spacing",
			properties = { "Size" },
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "Size" },
			propertyComponent = "X",
		},
	},
	["h"] = {
		{
			namespace = "spacing",
			properties = { "Size" },
			propertyComponent = "Y",
		},
	},
	["size"] = {
		{
			namespace = "spacing",
			properties = { "Size" },
		},
	},
	["min-w"] = {
		{
			namespace = "spacing",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
	},
	["min-h"] = {
		{
			namespace = "spacing",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "Y",
		},
	},
	["max-w"] = {
		{
			namespace = "spacing",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
	},
	["max-h"] = {
		{
			namespace = "spacing",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "Y",
		},
	},
	-- Logical sizing assumes horizontal writing mode
	["inline"] = {
		{
			namespace = "spacing",
			properties = { "Size" },
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "Size" },
			propertyComponent = "X",
		},
	},
	["block"] = {
		{
			namespace = "spacing",
			properties = { "Size" },
			propertyComponent = "Y",
		},
	},
	["min-inline"] = {
		{
			namespace = "spacing",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
	},
	["min-block"] = {
		{
			namespace = "spacing",
			properties = { "MinSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "Y",
		},
	},
	["max-inline"] = {
		{
			namespace = "spacing",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
		{
			namespace = "container",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "X",
		},
	},
	["max-block"] = {
		{
			namespace = "spacing",
			properties = { "MaxSize" },
			pseudoInstance = "UISizeConstraint",
			propertyComponent = "Y",
		},
	},
	["aspect"] = {
		{
			namespace = "aspect",
			properties = { "AspectRatio" },
			pseudoInstance = "UIAspectRatioConstraint",
		},
	},

	-- Positioning utils
	["inset"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
		},
	},
	["inset-x"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "X",
		},
	},
	["inset-y"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "Y",
		},
	},
	["top"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "Y",
		},
	},
	["left"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "X",
		},
	},
	-- Logical insets assume LTR
	["inset-s"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "X",
		},
	},
	["inset-bs"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "Y",
		},
	},

	-- Transform utils
	["translate"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
		},
	},
	["translate-x"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "X",
		},
	},
	["translate-y"] = {
		{
			namespace = "spacing",
			properties = { "Position" },
			propertyComponent = "Y",
		},
	},

	-- Image utils
	["fill"] = {
		{
			namespace = "color",
			properties = { "ImageColor3" },
		},
	},
	["stroke"] = {
		{
			namespace = "color",
			properties = { "ImageColor3" },
		},
	},

	-- Scrolling utils
	["scrollbar-thumb"] = {
		{
			namespace = "color",
			properties = { "ScrollBarImageColor3" },
		},
	},

	-- Layout utils
	["flex"] = {
		{
			namespace = "fill-direction",
			properties = { "FillDirection" },
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "flex-wrap",
			properties = { "Wraps" },
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "flex-mode",
			properties = { "FlexMode" },
			pseudoInstance = "UIFlexItem",
		},
	},
	["grid"] = {
		{
			namespace = "fill-direction",
			properties = { "FillDirection" },
			pseudoInstance = "UIGridLayout",
		},
	},
	["grid-flow"] = {
		{
			namespace = "fill-direction",
			properties = { "FillDirection" },
			pseudoInstance = "UIGridLayout",
		},
	},
	["grid-cols"] = {
		{
			namespace = "max-cells",
			properties = { "FillDirectionMaxCells" },
			manualProperties = { FillDirection = Enum.FillDirection.Horizontal },
			pseudoInstance = "UIGridLayout",
		},
	},
	["grid-rows"] = {
		{
			namespace = "max-cells",
			properties = { "FillDirectionMaxCells" },
			manualProperties = { FillDirection = Enum.FillDirection.Vertical },
			pseudoInstance = "UIGridLayout",
		},
	},
	["grow"] = {
		{
			namespace = "grow",
			properties = { "FlexMode" },
			pseudoInstance = "UIFlexItem",
		},
	},
	["shrink"] = {
		{
			namespace = "shrink",
			properties = { "FlexMode" },
			pseudoInstance = "UIFlexItem",
		},
	},
	["items"] = {
		{
			namespace = "item-alignment",
			properties = { "ItemLineAlignment" },
			pseudoInstance = "UIListLayout",
		},
	},
	["self"] = {
		{
			namespace = "item-alignment",
			properties = { "ItemLineAlignment" },
			pseudoInstance = "UIFlexItem",
		},
	},
	["justify"] = {
		{
			namespace = "horizontal-alignment",
			properties = { "HorizontalAlignment" },
			manualProperties = { HorizontalFlex = Enum.UIFlexAlignment.None },
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "flex-alignment",
			properties = { "HorizontalFlex" },
			pseudoInstance = "UIListLayout",
		},
	},
	["content"] = {
		{
			namespace = "vertical-alignment",
			properties = { "VerticalAlignment" },
			manualProperties = { VerticalFlex = Enum.UIFlexAlignment.None },
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "flex-alignment",
			properties = { "VerticalFlex" },
			pseudoInstance = "UIListLayout",
		},
	},
	["place-content"] = {
		{
			namespace = "place-content-start",
			properties = { "HorizontalAlignment" },
			manualProperties = {
				VerticalAlignment = Enum.VerticalAlignment.Top,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalFlex = Enum.UIFlexAlignment.None,
			},
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "place-content-center",
			properties = { "HorizontalAlignment" },
			manualProperties = {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalFlex = Enum.UIFlexAlignment.None,
			},
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "place-content-end",
			properties = { "HorizontalAlignment" },
			manualProperties = {
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalFlex = Enum.UIFlexAlignment.None,
			},
			pseudoInstance = "UIListLayout",
		},
		{
			namespace = "flex-alignment",
			properties = { "HorizontalFlex", "VerticalFlex" },
			pseudoInstance = "UIListLayout",
		},
	},
	["place-items"] = {
		{
			namespace = "item-alignment",
			properties = { "ItemLineAlignment" },
			pseudoInstance = "UIListLayout",
		},
	},
	["place-self"] = {
		{
			namespace = "item-alignment",
			properties = { "ItemLineAlignment" },
			pseudoInstance = "UIFlexItem",
		},
	},
	["order"] = {
		{
			namespace = "order",
			properties = { "LayoutOrder" },
		},
	},
	["z"] = {
		{
			namespace = "z",
			properties = { "ZIndex" },
		},
	},
	["hidden"] = {
		{
			namespace = "hidden",
			properties = { "Visible" },
		},
	},
	["visible"] = {
		{
			namespace = "visible",
			properties = { "Visible" },
		},
	},
	["auto"] = {
		{
			namespace = "automatic-size",
			properties = { "AutomaticSize" },
		},
	},
	["overflow"] = {
		{
			namespace = "overflow",
			properties = { "ClipsDescendants" },
		},
	},
	["object"] = {
		{
			namespace = "object",
			properties = { "ScaleType" },
		},
	},
	["pointer-events"] = {
		{
			namespace = "pointer-events",
			properties = { "Interactable" },
		},
	},

	-- Typography keywords
	["align"] = {
		{
			namespace = "align",
			properties = { "TextYAlignment" },
		},
	},
	["truncate"] = {
		{
			namespace = "text-truncate",
			properties = { "TextTruncate" },
		},
	},
	["whitespace"] = {
		{
			namespace = "whitespace",
			properties = { "TextWrapped" },
		},
	},

	-- Transform utils (continued)
	["scale"] = {
		{
			namespace = "scale",
			properties = { "Scale" },
			pseudoInstance = "UIScale",
		},
	},
	["rotate"] = {
		{
			namespace = "rotate",
			properties = { "Rotation" },
		},
	},

	-- Transition utils set the default transition, which applies to every property
	["transition"] = {
		{
			namespace = "duration",
			properties = { "*" },
			propertyComponent = "Time",
		},
	},
	["duration"] = {
		{
			namespace = "duration",
			properties = { "*" },
			propertyComponent = "Time",
		},
	},
	["ease"] = {
		{
			namespace = "ease",
			properties = { "*" },
			propertyComponent = "EasingStyle",
			subtokens = { direction = "EasingDirection" },
		},
	},
	["delay"] = {
		{
			namespace = "delay",
			properties = { "*" },
			propertyComponent = "DelayTime",
		},
	},
}

return table.freeze(PATTERNS)
