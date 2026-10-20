const function toUDim(unit: number)
	return UDim.new(0, unit)
end

const function toUDim2(unit: number)
	return UDim2.fromOffset(unit, unit)
end

const function toUDim2FromVector2(offset: Vector2 | number)
	if typeof(offset) == "number" then
		return toUDim2(offset)
	end
	return UDim2.fromOffset(offset.X, offset.Y)
end

const function toVector2(unit: number)
	return Vector2.new(unit, unit)
end

const function toTransparency(unit: number)
	return math.clamp(unit, 0, 1)
end

const function toFont(family: string | EnumItem)
	if typeof(family) == "string" then
		return Font.new(family)
	end
	return family :: any
end

const CONVERSIONS: { [string]: (any) -> any } = {
	Padding = toUDim,
	PaddingTop = toUDim,
	PaddingRight = toUDim,
	PaddingBottom = toUDim,
	PaddingLeft = toUDim,

	HorizontalPadding = toUDim,
	VerticalPadding = toUDim,

	CornerRadius = toUDim,
	TopLeftRadius = toUDim,
	TopRightRadius = toUDim,
	BottomRightRadius = toUDim,
	BottomLeftRadius = toUDim,

	Size = toUDim2,
	Position = toUDim2,
	MinSize = toVector2,
	MaxSize = toVector2,

	BlurRadius = toUDim,
	Offset = toUDim2FromVector2,
	Spread = toUDim2,

	Transparency = toTransparency,
	FontFace = toFont,
}

const function convertValue(property: string, value: any): any
	const convert = CONVERSIONS[property]
	if convert then
		return convert(value)
	else
		return value
	end
end

return convertValue
