export type Tokens = { [string]: any }

export type Tokenset = { [string]: any? }

export type Pattern = {
	namespace: string,
	properties: { string },
	manualProperties: { [string]: any }?,
	pseudoInstance: string?,
	propertyComponent: string?,
	subtokens: { [string]: string }?,
}

export type Component = {
	property: string,
	components: { [string]: any },
	selectorSuffix: string,
}

export type Rule = {
	selector: string,
	properties: { [string]: any },
	priority: number?,
	component: Component?,
}

type Placeholder = ""

export type function MergedTokensets(sets: type)
	local merged = {}
	local mergedIndexer = nil
	const indexer = sets:indexer()

	if indexer ~= nil then
		local element = indexer.readresult
		for _, set in if element:is("union") then element:components() else { element } do
			for key, prop in set:properties() do
				merged[key] = prop.read
			end

			mergedIndexer = set:indexer() or mergedIndexer
		end
	end

	return types.newtable(merged, mergedIndexer)
end

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

return nil
