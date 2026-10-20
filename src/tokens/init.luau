local mergeTokensets = require("./util/mergeTokensets")

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

return table.freeze(mergeTokensets({
	aspect,
	breakpoint,
	color,
	container,
	delay,
	duration,
	ease,
	font,
	insetShadow,
	fontWeight,
	leading,
	radius,
	shadow,
	spacing,
	border,
	text,
	textShadow,
	opacity,
	fillDirection,
	flexWrap,
	flexMode,
	grow,
	shrink,
	itemAlignment,
	hidden,
	visible,
	overflow,
	object,
	pointerEvents,
	align,
	textAlign,
	textWrapped,
	textTruncate,
	whitespace,
	order,
	rotate,
	scale,
	z,
}))
