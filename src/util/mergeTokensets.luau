local types = require("../types")

const function mergeTokensets<T>(tokensets: T & { types.Tokenset }): types.MergedTokensets<T>
	const mergedTokenset = {} :: types.Tokenset

	for _, tokenset in tokensets :: { types.Tokenset } do
		for token, value in tokenset do
			mergedTokenset[token] = value
		end
	end

	return mergedTokenset :: types.MergedTokensets<T>
end

return mergeTokensets
