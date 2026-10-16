local aspect = require("@self/namespaces/aspect")
local breakpoint = require("@self/namespaces/breakpoint")
local color = require("@self/namespaces/color")
local container = require("@self/namespaces/container")
local delay = require("@self/namespaces/delay")
local duration = require("@self/namespaces/duration")
local ease = require("@self/namespaces/ease")
local font = require("@self/namespaces/font")
local insetShadow = require("@self/namespaces/insetShadow")
local fontWeight = require("@self/namespaces/fontWeight")
local leading = require("@self/namespaces/leading")
local radius = require("@self/namespaces/radius")
local spacing = require("@self/namespaces/spacing")
local shadow = require("@self/namespaces/shadow")
local border = require("@self/namespaces/border")
local text = require("@self/namespaces/text")
local textShadow = require("@self/namespaces/textShadow")
local opacity = require("@self/namespaces/opacity")
local fillDirection = require("@self/namespaces/fillDirection")
local flexWrap = require("@self/namespaces/flexWrap")
local flexMode = require("@self/namespaces/flexMode")
local grow = require("@self/namespaces/grow")
local shrink = require("@self/namespaces/shrink")
local itemAlignment = require("@self/namespaces/itemAlignment")
local hidden = require("@self/namespaces/hidden")
local visible = require("@self/namespaces/visible")
local overflow = require("@self/namespaces/overflow")
local object = require("@self/namespaces/object")
local pointerEvents = require("@self/namespaces/pointerEvents")
local align = require("@self/namespaces/align")
local textAlign = require("@self/namespaces/textAlign")
local textWrapped = require("@self/namespaces/textWrapped")
local textTruncate = require("@self/namespaces/textTruncate")
local whitespace = require("@self/namespaces/whitespace")
local order = require("@self/namespaces/order")
local rotate = require("@self/namespaces/rotate")
local scale = require("@self/namespaces/scale")
local z = require("@self/namespaces/z")

type function MergedTokensets(sets: type)
	local merged = {}
	for _, set in sets:properties() do
		local setType = set.read
		if setType and setType:is("table") then
			for key, prop in setType:properties() do
				merged[key] = prop.read
			end
		end
	end
	return types.newtable(merged)
end

type function WithAll(sets: type)
	const props = {}

	for key, set in sets:properties() do
		props[key] = set.read
	end

	props[types.singleton("all")] = MergedTokensets(sets)
	return types.newtable(props)
end

export type Tokenset = { [string]: any }

local function mergeTokensets<T>(tokensets: T & { [string]: Tokenset }): MergedTokensets<T>
	const mergedTokenset = {} :: MergedTokensets<T>

	for _, tokenset in tokensets :: { [string]: Tokenset } do
		for token, value in tokenset do
			(mergedTokenset :: Tokenset)[token] = value
		end
	end

	return mergedTokenset
end

local function withAll<T>(tokensets: T & { [string]: Tokenset }): WithAll<T>
	tokensets.all = mergeTokensets(tokensets)
	return tokensets
end

const PRIMITIVES = {
	aspect = aspect,
	breakpoint = breakpoint,
	color = color,
	container = container,
	delay = delay,
	duration = duration,
	ease = ease,
	font = font,
	["inset-shadow"] = insetShadow,
	["font-weight"] = fontWeight,
	leading = leading,
	radius = radius,
	shadow = shadow,
	spacing = spacing,
	border = border,
	text = text,
	["text-shadow"] = textShadow,
	opacity = opacity,
	["fill-direction"] = fillDirection,
	["flex-wrap"] = flexWrap,
	["flex-mode"] = flexMode,
	["grow"] = grow,
	["shrink"] = shrink,
	["item-alignment"] = itemAlignment,
	["hidden"] = hidden,
	["visible"] = visible,
	["overflow"] = overflow,
	["object"] = object,
	["pointer-events"] = pointerEvents,
	["align"] = align,
	["text-align"] = textAlign,
	["text-wrapped"] = textWrapped,
	["text-truncate"] = textTruncate,
	["whitespace"] = whitespace,
	order = order,
	rotate = rotate,
	scale = scale,
	z = z,
}

return table.freeze(withAll(PRIMITIVES))
