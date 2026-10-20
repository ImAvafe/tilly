export type Tokenset = { [string]: any? }

type function MergedTokensets(sets: type)
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

const function mergeTokensets<T>(tokensets: T & { Tokenset }): MergedTokensets<T>
	const mergedTokenset = {} :: Tokenset

	for _, tokenset in tokensets :: { Tokenset } do
		for token, value in tokenset do
			mergedTokenset[token] = value
		end
	end

	return mergedTokenset :: MergedTokensets<T>
end

return mergeTokensets
