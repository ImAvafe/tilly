--!strict

local patterns = require("./patterns")

export type Generated = {
	tag: string,
	prefix: string,
	pattern: patterns.Pattern,
}

export type Tags = {
	generated: { Generated },
	samples: { Generated }, -- One tag per pattern, to try variants on
	variants: { string },
}

const MULTIPLIERS = { "0", "1", "2", "4", "10", "50", "100", "300" }
const SPACING_MULTIPLIERS = { "0.5", "1.5", "px" }
const VARIANTS = {
	"hover:",
	"active:",
	"disabled:",
	"*:",
	"**:",
	"hover:active:",
	"*:hover:",
	"**:disabled:",
}

const namespaces: { [string]: boolean } = {}
for _, prefixPatterns in patterns do
	for _, pattern in prefixPatterns do
		namespaces[pattern.namespace] = true
	end
end

--[[
	Every value of `pattern` that `resolveTag` accepts: its tokens, plus multipliers of a base token.
]]
const function generateValues(pattern: patterns.Pattern, tokens: { [string]: any }): { string }
	const namespace = pattern.namespace
	const values = {}
	const seen = {}
	const function add(value: string)
		if not seen[value] then
			seen[value] = true
			table.insert(values, value)
		end
	end

	for key in tokens do
		if type(key) ~= "string" or string.sub(key, 1, #namespace + 1) ~= `{namespace}-` then
			continue
		end

		-- Tokens of a longer namespace, like `text-align-left` under `text`, belong to that namespace
		local owned = false
		for other in namespaces do
			if #other > #namespace and string.sub(key, 1, #other + 1) == `{other}-` then
				owned = true
				break
			end
		end
		if owned then
			continue
		end

		const rest = string.sub(key, #namespace + 2)
		const value = string.match(rest, "^(.-)%-%-") or rest
		if value == "" then
			continue
		end

		local resolves = tokens[`{namespace}-{value}`] ~= nil
		for subtoken in pattern.subtokens or {} do
			resolves = resolves or tokens[`{namespace}-{value}--{subtoken}-1`] ~= nil
		end
		if resolves then
			add(value)
		end
	end

	if type(tokens[namespace]) == "number" then
		for _, multiplier in MULTIPLIERS do
			add(multiplier)
		end
		if namespace == "spacing" then
			for _, multiplier in SPACING_MULTIPLIERS do
				add(multiplier)
			end
		end
	end

	table.sort(values)
	return values
end

--[[
	Builds every tag that the patterns and `tokens` (the merged tokenset) allow.
]]
const function generateTags(tokens: { [string]: any }): Tags
	const prefixes = {}
	for prefix in patterns do
		table.insert(prefixes, prefix)
	end
	table.sort(prefixes)

	const generated: { Generated } = {}
	const generatedTags: { [string]: boolean } = {}
	const samples: { Generated } = {}

	for _, prefix in prefixes do
		for _, pattern in patterns[prefix] do
			const tags = {}
			for _, value in generateValues(pattern, tokens) do
				table.insert(tags, `{prefix}-{value}`)
			end
			-- Standalone utilities (`rounded`, `transition`) resolve their `default` value
			if not string.find(prefix, "-", 1, true) and table.find(tags, `{prefix}-default`) then
				table.insert(tags, prefix)
			end

			local sampled = false
			for _, tag in tags do
				if generatedTags[tag] then
					continue
				end
				generatedTags[tag] = true

				const entry = {
					tag = tag,
					prefix = prefix,
					pattern = pattern,
				}
				table.insert(generated, entry)
				if not sampled then
					sampled = true
					table.insert(samples, entry)
				end
			end
		end
	end

	return {
		generated = generated,
		samples = samples,
		variants = VARIANTS,
	}
end

return generateTags
