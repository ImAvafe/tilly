const function sanitizeTag(tag: string): string
	local sanitizedTag = tag
	sanitizedTag = string.gsub(sanitizedTag, "%*%*", "desc")
	sanitizedTag = string.gsub(sanitizedTag, "%*", "child")
	sanitizedTag = string.gsub(sanitizedTag, "!", "_important")
	sanitizedTag = string.gsub(sanitizedTag, "[:%.]", "_")
	return sanitizedTag
end

return sanitizeTag
