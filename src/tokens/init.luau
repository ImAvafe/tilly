local mergeTokensets = require("./util/mergeTokensets")

local aspect = require("@self/aspect")
local automaticSize = require("@self/automaticSize")
local breakpoint = require("@self/breakpoint")
local color = require("@self/color")
local container = require("@self/container")
local delay = require("@self/delay")
local duration = require("@self/duration")
local ease = require("@self/ease")
local font = require("@self/font")
local fraction = require("@self/fraction")
local insetShadow = require("@self/insetShadow")
local fontWeight = require("@self/fontWeight")
local leading = require("@self/leading")
local radius = require("@self/radius")
local spacing = require("@self/spacing")
local shadow = require("@self/shadow")
local border = require("@self/border")
local text = require("@self/text")
local textShadow = require("@self/textShadow")
local opacity = require("@self/opacity")
local fillDirection = require("@self/fillDirection")
local flexWrap = require("@self/flexWrap")
local flexMode = require("@self/flexMode")
local grow = require("@self/grow")
local shrink = require("@self/shrink")
local itemAlignment = require("@self/itemAlignment")
local horizontalAlignment = require("@self/horizontalAlignment")
local verticalAlignment = require("@self/verticalAlignment")
local flexAlignment = require("@self/flexAlignment")
local placeContent = require("@self/placeContent")
local maxCells = require("@self/maxCells")
local hidden = require("@self/hidden")
local visible = require("@self/visible")
local overflow = require("@self/overflow")
local object = require("@self/object")
local pointerEvents = require("@self/pointerEvents")
local align = require("@self/align")
local textAlign = require("@self/textAlign")
local textWrapped = require("@self/textWrapped")
local textTruncate = require("@self/textTruncate")
local whitespace = require("@self/whitespace")
local order = require("@self/order")
local rotate = require("@self/rotate")
local scale = require("@self/scale")
local z = require("@self/z")

return table.freeze(mergeTokensets({
	aspect,
	automaticSize,
	breakpoint,
	color,
	container,
	delay,
	duration,
	ease,
	font,
	fraction,
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
	horizontalAlignment,
	verticalAlignment,
	flexAlignment,
	placeContent,
	maxCells,
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
