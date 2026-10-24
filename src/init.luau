local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require("@self/propertyDefaults")
local resolveTag = require("@self/resolveTag")

type Placeholder = "我们今" 

type function AssertStringSingleton(target: type, errorMessage: string)
	const value = if target.tag == "singleton" then target:value() else error(errorMessage)
	return type(value) == "string" and value or error(errorMessage)
end

type function WithTokens(defaultTokens: type, tokensType: type)
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

type function AutocompleteTags(tokensType: type, tagsType: type)
	const tags = AssertStringSingleton(tagsType, "expected tags to be a string singleton")

	const fragment = string.match(tags, "(%S+)$")
	const needle = fragment or ""

	local components = {}
	for key in tokensType:properties() do
		const token = AssertStringSingleton(key, "expected token keys to be string singletons")
		if token ~= needle and string.sub(token, 1, #needle) == needle then
			table.insert(components, types.singleton(token))
		end
	end

	const numComponents = #components
	return if numComponents == 0 then types.never elseif numComponents == 1 then components[1] else types.unionof(table.unpack(components))
end

type AddTag<Tokens> = <Tags>(instance: Instance, tags: Tags | Placeholder | AutocompleteTags<Tokens, Tags>) -> ()

const function tilly<Tokens>(styleSheet: StyleSheet, tokens: Tokens?)
	const mergedTokens: mergeTokensets.Tokenset = (mergeTokensets :: any)({ defaultTokens, tokens or {} })
	const resolvedStyleRules = {} :: { [string]: StyleRule | false }

	-- Load instance property defaults
	for className, properties in propertyDefaults do
		const styleRule = Instance.new("StyleRule")
		styleRule.Selector = className
		styleRule:SetProperties(properties)
		styleRule.Parent = styleSheet
		styleRule.Priority = -1
		styleRule.Name = className
	end

	const function addTags(instance: Instance, tags: string)
		const tagsArray = string.split(tags, " ")

		for _, tag in tagsArray do
			const sanitizedTag = string.gsub(tag, "[:%.]", "_")
			instance:AddTag(sanitizedTag)

			if resolvedStyleRules[tag] == nil then
				const freshTagRule = resolveTag(tag, mergedTokens :: { [string]: any })

				if freshTagRule ~= nil then
					const styleRule = Instance.new("StyleRule")
					styleRule.Selector = freshTagRule.selector
					styleRule:SetProperties(freshTagRule.properties)
					styleRule.Priority = freshTagRule.priority or 0
					styleRule.Name = freshTagRule.selector
					styleRule.Parent = styleSheet
					resolvedStyleRules[tag] = styleRule
				else
					-- Tag is invalid and should never be considered
					resolvedStyleRules[tag] = false
				end
			end
		end
	end

	const function destroy()
		for _, styleRule in resolvedStyleRules do
			if styleRule then
				styleRule:Destroy()
			end
		end
	end

	return addTags :: AddTag<WithTokens<typeof(defaultTokens), typeof(tokens)>>, destroy
end

const tags = tilly(Instance.new("StyleSheet"), {
	["some-bullshit"] = 100
})

tags(workspace, "p-20 color-amber-100")


























return tilly
