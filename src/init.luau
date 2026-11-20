local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require("@self/propertyDefaults")
local resolveTag = require("@self/resolveTag")
local sanitizeTag = require("@self/util/sanitizeTag")
local withComponents = require("@self/util/withComponents")

type Placeholder = ""

type function AssertStringSingleton(target: type, errorMessage: string)
	const value = if target.tag == "singleton" then target:value() else error(errorMessage)
	return type(value) == "string" and value or error(errorMessage)
end

type function StartsWith(s: string, prefix: string)
	return string.sub(s, 1, string.len(prefix)) == prefix
end

export type function WithTokens(defaultTokens: type, tokensType: type)
	const tokens = tokensType.tag == "union" and tokensType:components()[1] or tokensType
	if tokens.tag ~= "table" then
		return defaultTokens
	end

	const result = types.copy(defaultTokens)
	for key, value in tokens:properties() do
		result:setreadproperty(key, value.read)
	end

	return result
end

export type function AutocompleteTags(tokensType: type, tagsType: type)
	-- Reactive tags are computed at runtime, so there's no string to complete
	if tagsType.tag == "function" then
		return types.never
	end

	const VARIANTS = { "hover", "active", "disabled", "*", "**" }
	const IS_VARIANT = {}
	for _, variant in VARIANTS do
		IS_VARIANT[variant] = true
	end

	const tags = AssertStringSingleton(tagsType, "expected tags to be a string singleton")

	const fragment = string.match(tags, "(%S+)$") or ""

	local rest = fragment
	local variantFragment = ""
	local usedVariants = {}
	while true do
		const variant, remainder = string.match(rest, "^([%w%-%*]+):(.*)$")
		if not variant or not IS_VARIANT[variant] then
			break
		end
		usedVariants[variant] = true
		variantFragment ..= variant .. ":"
		rest = remainder or rest
	end

	local components = {}

	for _, variant in VARIANTS do
		if not usedVariants[variant] and StartsWith(variant, rest) then
			table.insert(components, types.singleton(variant .. ":"))
		end
	end

	for key in tokensType:properties() do
		const token = AssertStringSingleton(key, "expected token keys to be string singletons")
		if token ~= rest and StartsWith(token, rest) then
			table.insert(components, types.singleton(token))
		end
	end

	const numComponents = #components

	return if numComponents == 0
		then types.never
		elseif numComponents == 1 then components[1]
		else types.unionof(table.unpack(components))
end

export type TagsInput<Tokens, Tags> = Tags | Placeholder | AutocompleteTags<Tokens, Tags>

export type AddTag<Tokens> = <Tags>(instance: Instance, tags: TagsInput<Tokens, Tags>) -> () -> ()

export type DefaultTokens = typeof(defaultTokens)

const function tilly<Tokens>(styleSheet: StyleSheet, tokens: Tokens?)
	const mergedTokens: mergeTokensets.Tokenset = (mergeTokensets :: any)({ defaultTokens, tokens or {} })
	-- Keyed by tag, or by selector for compound rules
	const resolvedStyleRules = {} :: { [string]: StyleRule | false }
	-- Rules that set one component of a composite property, keyed by sanitized tag
	const componentRules = {} :: { [string]: resolveTag.Rule }

	const function createStyleRule(selector: string, properties: { [string]: any }, priority: number): StyleRule
		const styleRule = Instance.new("StyleRule")
		styleRule.Selector = selector
		for property, value in properties do
			if typeof(value) == "TweenInfo" then
				styleRule:SetPropertyTransition(property, value)
			else
				styleRule:SetProperty(property, value)
			end
		end
		styleRule.Priority = priority
		styleRule.Name = selector
		styleRule.Parent = styleSheet
		return styleRule
	end

	-- Load instance property defaults
	const defaultRules = {} :: { StyleRule }
	for className, properties in propertyDefaults do
		table.insert(defaultRules, createStyleRule(className, properties, -1))
	end

	const function addCompositeRules(instance: Instance)
		-- Components keyed by tag, grouped by the property they set
		const groups: { [string]: { [string]: resolveTag.Component } } = {}

		for _, tag in instance:GetTags() do
			const component = componentRules[tag] and componentRules[tag].component
			if component then
				const key = component.property .. component.selectorSuffix
				if groups[key] == nil then
					groups[key] = {}
				end
				groups[key][tag] = component
			end
		end

		for _, components in groups do
			const tags = {}
			for tag in components do
				table.insert(tags, tag)
			end

			if #tags < 2 then
				continue
			end

			table.sort(tags, function(a: string, b: string)
				return string.lower(a) < string.lower(b)
			end)

			const component = components[tags[1]]
			const selector = `.{table.concat(tags, ".")}{component.selectorSuffix}`
			if resolvedStyleRules[selector] ~= nil then
				continue
			end

			-- Components from explicit values (`duration-300`) override defaults (`transition`)
			const tagsByPriority = table.clone(tags)
			table.sort(tagsByPriority, function(a: string, b: string)
				return (componentRules[a].priority or 0) < (componentRules[b].priority or 0)
			end)

			local value = componentRules[tags[1]].properties[component.property]
			for _, tag in tagsByPriority do
				value = withComponents(value, components[tag].components)
			end
			const priority = componentRules[tagsByPriority[#tagsByPriority]].priority or 0
			resolvedStyleRules[selector] = createStyleRule(selector, { [component.property] = value }, priority + 1)
		end
	end

	const function addTags(instance: Instance, tags: string): () -> ()
		const tagsArray = string.split(tags, " ")

		for _, tag in tagsArray do
			const sanitizedTag = sanitizeTag(tag)
			instance:AddTag(sanitizedTag)

			if resolvedStyleRules[tag] == nil then
				const rule = resolveTag(tag, mergedTokens :: { [string]: any })

				-- An invalid tag is stored as false so it's never resolved again
				resolvedStyleRules[tag] = if rule ~= nil
					then createStyleRule(rule.selector, rule.properties, rule.priority or 0)
					else false

				if rule ~= nil and rule.component ~= nil then
					componentRules[sanitizedTag] = rule
				end
			end
		end
		addCompositeRules(instance)

		return function()
			for _, tag in tagsArray do
				instance:RemoveTag(sanitizeTag(tag))
			end
			addCompositeRules(instance)
		end
	end

	const function destroy()
		for _, styleRule in defaultRules do
			styleRule:Destroy()
		end
		for _, styleRule in resolvedStyleRules do
			if styleRule then
				styleRule:Destroy()
			end
		end
	end

	return addTags :: AddTag<WithTokens<typeof(defaultTokens), typeof(tokens)>>, destroy
end

return tilly
