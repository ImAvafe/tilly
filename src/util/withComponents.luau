-- Rebuilds a composite value with some of its components replaced
const CONSTRUCTORS: { [string]: { new: (...any) -> any, components: { string } } } = {
	Font = {
		new = Font.new,
		components = { "Family", "Weight", "Style" },
	},
	UDim2 = {
		new = UDim2.new,
		components = { "X", "Y" },
	},
	Vector2 = { new = Vector2.new, components = { "X", "Y" } },
	TweenInfo = {
		new = TweenInfo.new,
		components = { "Time", "EasingStyle", "EasingDirection", "RepeatCount", "Reverses", "DelayTime" },
	},
}

const function withComponents(value: any, replacements: { [string]: any }): any
	const constructor = CONSTRUCTORS[typeof(value)]
	const arguments = {}
	for index, component in constructor.components do
		arguments[index] = if replacements[component] ~= nil then replacements[component] else value[component]
	end
	return constructor.new(table.unpack(arguments))
end

return withComponents
