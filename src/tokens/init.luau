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
}

return table.freeze(withAll(PRIMITIVES))
