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
	return styleRule
end

return createStyleRule
