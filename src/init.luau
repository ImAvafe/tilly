local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require("@self/util/propertyDefaults")
local resolveTag = require("@self/resolveTag")
local sanitizeTag = require("@self/util/sanitizeTag")
local types = require("@self/types")
local withComponents = require("@self/util/withComponents")

export type AutocompleteTags<Tokens, Tags> = types.AutocompleteTags<Tokens, Tags>
export type TagsInput<Tokens, Tags> = types.TagsInput<Tokens, Tags>
export type AddTag<Tokens> = types.AddTag<Tokens>
export type DefaultTokens = typeof(defaultTokens)

const function tilly<Tokens>(styleSheet: StyleSheet, tokens: Tokens?)
	const mergedTokens: types.Tokenset = (mergeTokensets :: any)({ defaultTokens, tokens or {} })
	const resolvedStyleRules = {} :: { [string]: StyleRule | false }
	const componentRules = {} :: { [string]: types.Rule }

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
		const groups: { [string]: { [string]: types.Component } } = {}

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
		local hasComponent = false

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

			if componentRules[sanitizedTag] ~= nil then
				hasComponent = true
			end
		end
		if hasComponent then
			addCompositeRules(instance)
		end

		return function()
			for _, tag in tagsArray do
				instance:RemoveTag(sanitizeTag(tag))
			end
			if hasComponent then
				addCompositeRules(instance)
			end
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

	return addTags :: types.AddTag<types.WithTokens<typeof(defaultTokens), typeof(tokens)>>, destroy
end

return tilly
