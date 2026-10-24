local convertValue = require("./util/convertValue")
local patterns = require("./patterns")

const VARIANT_GUI_STATES = {
	hover = Enum.GuiState.Hover.Name,
	active = Enum.GuiState.Press.Name,
	disabled = Enum.GuiState.NonInteractable.Name,
}

export type Rule = {
	selector: string,
	properties: { [string]: any },
	priority: number?,
	propertyComponent: string?,
}
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

const function resolvePattern(
	tag: string,
	pattern: patterns.Pattern,
	tagValue: string,
	variants: { string },
	mergedTokens: Tokens
): Rule?
	const hardcodedToken = (mergedTokens :: Tokens)[`{pattern.namespace}-{tagValue}`]
	const baseMultiplierToken = (mergedTokens :: Tokens)[pattern.namespace]
	const multiplier = parseMultiplier(tagValue)
	const guiStateSuffix = variantsToGuiStateSuffix(variants)

	if hardcodedToken ~= nil or (baseMultiplierToken and multiplier) then
		const endValue = if hardcodedToken ~= nil then hardcodedToken else baseMultiplierToken * multiplier
		const properties = {}

		for _, property in pattern.properties do
			if endValue ~= nil then
				properties[property] = convertValue(property, endValue)
			end
		end

		if pattern.manualProperties ~= nil then
			for property, value in pattern.manualProperties do
				properties[property] = value
			end
		end

		if next(properties) ~= nil then
			const sanitizedTag = string.gsub(tag, "[:%.]", "_")
			return {
				selector = if pattern.pseudoInstance
					then `.{sanitizedTag}::{pattern.pseudoInstance}{guiStateSuffix}`
					else `.{sanitizedTag}{guiStateSuffix}`,
				properties = properties,
				priority = if #variants > 0 then 1 else 0,
			}
		end
	end

	return nil
end

const function resolveTag(tag: string, tokens: Tokens): Rule?
	const variants = string.split(tag, ":")
	const utilityParts = string.split(variants[#variants], "-")
	table.remove(variants, #variants)

	for _, part in utilityParts do
		if part == "" then
			return nil
		end
	end

	-- Direct resolution for standalone utilities
	if #utilityParts == 1 then
		for _, pattern in patterns[tag] or {} do
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
	warn(`\"{tag}\"`, "utility tag is not valid.")

	return nil
end

return resolveTag
