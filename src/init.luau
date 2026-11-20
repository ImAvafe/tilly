local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require("@self/util/propertyDefaults")
local resolveTag = require("@self/resolveTag")
local sanitizeTag = require("@self/util/sanitizeTag")
local types = require("@self/types")
local createStyleRule = require("@self/util/createStyleRule")
local withComponents = require("@self/util/withComponents")

export type AutocompleteTags<Tokens, Tags> = types.AutocompleteTags<Tokens, Tags>
export type TagsInput<Tokens, Tags> = types.TagsInput<Tokens, Tags>
export type AddTag<Tokens> = types.AddTag<Tokens>
export type DefaultTokens = typeof(defaultTokens)

export type Tilly<Tokens> = {
	_styleSheet: StyleSheet,
	_tokens: types.Tokenset,
	_defaultRules: { StyleRule },
	_resolvedStyleRules: { [string]: StyleRule | false },
	_componentRules: { [string]: types.Rule },
	_addCompositeRules: (self: Tilly<Tokens>, instance: Instance) -> (),

	addTags: <Tags>(self: Tilly<Tokens>, instance: Instance, tags: TagsInput<Tokens, Tags>) -> () -> (),
	destroy: (self: Tilly<Tokens>) -> (),
}

const Tilly = {}
Tilly.__index = Tilly

function Tilly._addCompositeRules(self: Tilly<any>, instance: Instance)
	const resolvedStyleRules = self._resolvedStyleRules
	const componentRules = self._componentRules

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
		const styleRule = createStyleRule(selector, { [component.property] = value }, priority + 1)
		styleRule.Parent = self._styleSheet
		resolvedStyleRules[selector] = styleRule
	end
end

--[[
Constructs a new Tilly object, pointed at the given stylesheet. Pass in custom tokens for theming
]]
function Tilly.new<Tokens>(styleSheet: StyleSheet, tokens: Tokens?)
	const self = {
		_styleSheet = styleSheet,
		_tokens = (mergeTokensets :: any)({ defaultTokens, tokens or {} }),
		_defaultRules = {} :: { StyleRule },
		_resolvedStyleRules = {},
		_componentRules = {},
	} :: Tilly<types.WithTokens<typeof(defaultTokens), typeof(tokens)>>
	setmetatable(self, Tilly)

	for className, properties in propertyDefaults do
		const styleRule = createStyleRule(className, properties, -1)
		styleRule.Parent = styleSheet
		table.insert(self._defaultRules, styleRule)
	end

	return self
end

--[[
Applies tags to the given instance and returns a function that removes them
]]
function Tilly.addTags(self: Tilly<any>, instance: Instance, tags: string): () -> ()
	const resolvedStyleRules = self._resolvedStyleRules
	const componentRules = self._componentRules
	const tagsArray = string.split(tags, " ")
	local hasComponent = false

	for _, tag in tagsArray do
		const sanitizedTag = sanitizeTag(tag)
		instance:AddTag(sanitizedTag)

		if resolvedStyleRules[tag] == nil then
			const rule = resolveTag(tag, self._tokens :: { [string]: any })

			-- An invalid tag is stored as false so it's never resolved again
			if rule ~= nil then
				const styleRule = createStyleRule(rule.selector, rule.properties, rule.priority or 0)
				styleRule.Parent = self._styleSheet
				resolvedStyleRules[tag] = styleRule
			else
				resolvedStyleRules[tag] = false
			end

			if rule ~= nil and rule.component ~= nil then
				componentRules[sanitizedTag] = rule
			end
		end

		if componentRules[sanitizedTag] ~= nil then
			hasComponent = true
		end
	end
	if hasComponent then
		self:_addCompositeRules(instance)
	end

	return function()
		for _, tag in tagsArray do
			instance:RemoveTag(sanitizeTag(tag))
		end
		if hasComponent then
			self:_addCompositeRules(instance)
		end
	end
end

--[[
Destroys every `StyleRule` this Tilly object created
]]
function Tilly.destroy(self: Tilly<any>)
	for _, styleRule in self._defaultRules do
		styleRule:Destroy()
	end
	for _, styleRule in self._resolvedStyleRules do
		if styleRule then
			styleRule:Destroy()
		end
	end
end

return Tilly
