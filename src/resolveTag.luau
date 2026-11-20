local convertValue = require("./util/convertValue")
local patterns = require("./patterns")
local sanitizeTag = require("./util/sanitizeTag")
local withComponents = require("./util/withComponents")

const VARIANT_GUI_STATES = {
	hover = Enum.GuiState.Hover.Name,
	active = Enum.GuiState.Press.Name,
	disabled = Enum.GuiState.NonInteractable.Name,
}

const VARIANT_COMBINATORS = {
	["*"] = " > GuiObject",
	["**"] = " >> GuiObject",
}

export type Rule = {
	selector: string,
	properties: { [string]: any },
	priority: number?,
	component: Component?,
}
export type Component = { property: string, components: { [string]: any }, selectorSuffix: string }
export type Tokens = { [string]: any }

const function parseMultiplier(multiplier: string): number?
	if multiplier == "px" then
		return 1
	end
	if string.match(multiplier, "^%d+$") or string.match(multiplier, "^%d+%.%d+$") then
		return tonumber(multiplier)
	end
	return nil
end

const function variantsToGuiStateSuffix(variants: { string }): string
	local guiStatesSuffix = ""
	for _, variant in variants do
		const guiState = VARIANT_GUI_STATES[variant]
		if guiState ~= nil then
			guiStatesSuffix = `{guiStatesSuffix}:{guiState}`
		end
	end
	return guiStatesSuffix
end

const function variantsToCombinator(variants: { string }): string
	for _, variant in variants do
		const combinator = VARIANT_COMBINATORS[variant]
		if combinator ~= nil then
			return combinator
		end
	end
	return ""
end

const function compositeBase(property: string, tokens: Tokens): any
	if property == "FontFace" then
		return Font.new(tokens["font-sans"], tokens["font-weight-normal"])
	elseif property == "MinSize" then
		return Vector2.zero
	elseif property == "MaxSize" then
		return Vector2.new(math.huge, math.huge)
	elseif property == "*" then
		return TweenInfo.new(tokens["duration-default"], tokens["ease-default"], tokens["ease-default--direction"])
	end
	return UDim2.new()
end

const function resolveProperties(pattern: patterns.Pattern, tagValue: string, tokens: Tokens): { [string]: any }?
	const token = tokens[`{pattern.namespace}-{tagValue}`]
	const baseMultiplierToken = tokens[pattern.namespace]
	const multiplier = parseMultiplier(tagValue)
	const properties = {}

	if token ~= nil or (baseMultiplierToken and multiplier) then
		const value = if token ~= nil then token else baseMultiplierToken * multiplier
		for _, property in pattern.properties do
			properties[property] = convertValue(property, value)
		end
	elseif pattern.subtokens ~= nil then
		for subtoken, property in pattern.subtokens do
			const value = tokens[`{pattern.namespace}-{tagValue}--{subtoken}-1`]
			if value ~= nil then
				properties[property] = convertValue(property, value)
			end
		end
	end

	if next(properties) == nil then
		return nil
	end
	for property, value in pattern.manualProperties or {} do
		properties[property] = value
	end
	return properties
end

const function resolvePattern(
	tag: string,
	pattern: patterns.Pattern,
	tagValue: string,
	variants: { string },
	tokens: Tokens
): Rule?
	const properties = resolveProperties(pattern, tagValue, tokens)
	if properties == nil then
		return nil
	end

	const pseudoInstance = if pattern.pseudoInstance then `::{pattern.pseudoInstance}` else ""
	const selectorSuffix = `{variantsToCombinator(variants)}{variantsToGuiStateSuffix(variants)}{pseudoInstance}`
	const isImportant = string.sub(tag, -1) == "!"
	const specificity = 4 - #pattern.properties + (if tagValue == "default" then 0 else 1)

	local component = nil
	if pattern.propertyComponent ~= nil then
		const property = pattern.properties[1]
		const base = compositeBase(property, tokens)
		const value = properties[property]
		const components = {
			[pattern.propertyComponent] = if typeof(value) == typeof(base)
				then value[pattern.propertyComponent]
				else value,
		}

		for subtoken, name in pattern.subtokens or {} do
			components[name] = tokens[`{pattern.namespace}-{tagValue}--{subtoken}`]
		end

		properties[property] = withComponents(base, components)
		component = {
			property = property,
			components = components,
			selectorSuffix = selectorSuffix,
		}
	end

	return {
		selector = `.{sanitizeTag(tag)}{selectorSuffix}`,
		properties = properties,
		priority = (if isImportant then 100 else 0) + #variants * 10 + specificity,
		component = component,
	}
end

const function resolveTag(tag: string, tokens: Tokens): Rule?
	const variants = string.split(tag, ":")
	const utility = string.gsub(variants[#variants], "!$", "")
	const utilityParts = string.split(utility, "-")
	table.remove(variants, #variants)

	for _, part in utilityParts do
		if part == "" then
			return nil
		end
	end

	-- Direct resolution for standalone utilities
	if #utilityParts == 1 then
		for _, pattern in patterns[utilityParts[1]] or {} do
			const rule = resolvePattern(tag, pattern, "default", variants, tokens)
			if rule then
				return rule
			end
		end
	end

	-- Walk the tag's parts until a match is found
	for i = #utilityParts - 1, 1, -1 do
		const prefix = table.concat(utilityParts, "-", 1, i)
		const value = table.concat(utilityParts, "-", i + 1)
		const utilityPatterns = patterns[prefix]

		if utilityPatterns then
			for _, pattern in utilityPatterns do
				const rule = resolvePattern(tag, pattern, value, variants, tokens)
				if rule then
					return rule
				end
			end
		end
	end

	-- aw man :<
	warn(`\"{tag}\"`, "utility tag is not valid.", debug.traceback())

	return nil
end

return resolveTag
