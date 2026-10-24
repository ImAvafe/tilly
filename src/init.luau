local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require("@self/propertyDefaults")
local resolveTag = require("@self/resolveTag")

type Placeholder = "我们今" 

type function AutocompleteTags(tokensType: type, tagsType: type)
	const function assertStringSingleton(target: type, errorMessage: string)
		const value = if target.tag == "singleton" then target:value() else error(errorMessage)
		return type(value) == "string" and value or error(errorMessage)
	end

	const tags = assertStringSingleton(tagsType, "expected tags to be a string singleton")

	const fragment = string.match(tags, "(%S+)$")
	const needle = fragment or ""

	local components = {}
	for key in tokensType:properties() do
		const token = assertStringSingleton(key, "expected token keys to be string singletons")
		if token ~= needle and string.sub(token, 1, #needle) == needle then
			table.insert(components, types.singleton(token))
		end
	end

	return if #components == 1 then types.never else types.unionof(table.unpack(components))
end

type AddTag<Tokens> = <Tags>(instance: Instance, tags: Tags | Placeholder | AutocompleteTags<Tokens, Tags>) -> ()

const function tilly<T>(styleSheet: StyleSheet, tokens: (T | { [string]: any })?)
	const mergedTokens = mergeTokensets({ defaultTokens, tokens or {} })
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

	return addTags :: AddTag<typeof(defaultTokens)>, destroy
end

const tags = tilly(Instance.new("StyleSheet"))

tags(workspace, "color-amber-100 text-2xl scale-none aspect-video radius-4xl pointer-events-auto")


























return tilly
