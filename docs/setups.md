# For your framework

If you use a UI library like Vide or Fusion, we're going to overwrite that `tag.luau` module to make using Tilly more convenient.

Otherwise, feel free to ignore this page!

```[File structure]
- style
	- styleSheet.luau
	- tokens.luau
	- tag.luau <-- PASTE INTO HERE
	- init.luau
```

::: code-group

```luau [Vide]
const tilly = require("@src/vendor/tilly")
const vide = require("@packages/vide")
const styleSheet = require("@src/style/styleSheet")
const tokens = require("@src/style/tokens")

vide.defaults = false -- disables default properties that interfere with our styling

const addTags = tilly(styleSheet, tokens)

const function tag<Tags>(tags: tilly.TagsInput<typeof(tokens), Tags>)
	return vide.action(function(instance)
		if type(tags) == "string" then
			addTags(instance, tags)
			return
		end

		if type(tags) == "function" then
			local removeTags: (() -> ())? = nil
			vide.effect(function()
				if removeTags ~= nil then
					removeTags()
					removeTags = nil
				end
				removeTags = addTags(instance, (tags :: any)() :: "")
			end)
		end
	end)
end

return tag
```

```luau [Fusion]
-- anyone wanna suggest a snippet for this?
```

```luau [React]
-- anyone wanna suggest a snippet for this?
```

```luau [Others]
-- feel free to PR for more frameworks
```

:::
