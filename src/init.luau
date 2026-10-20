local mergeTokensets = require("@self/util/mergeTokensets")
local defaultTokens = require("@self/tokens")
local propertyDefaults = require(script.propertyDefaults)
local resolveTag = require(script.resolveTag)

const function tilly(styleSheet: StyleSheet, tokens: { [string]: any }?)
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

	return addTags, destroy
end

return tilly
