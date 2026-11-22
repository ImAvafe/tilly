# Get started

## Install

Tilly is distributed via Wally and GitHub releases.

### Using Wally

1. Copy the latest version from [Wally](https://wally.run/package/imavafe/avalog)
2. Paste it into your `wally.toml` under dependencies
3. Run `wally install`

### Using Roblox Studio

1. Open the latest release on [GitHub](https://github.com/ImAvafe/tilly/releases/latest)
2. Download the file ending in `.rbxm`
3. Drag the file into Roblox Studio

## Instantiate Tilly

::: code-group

```luau [myTilly.luau]
const Tilly = require("@packages/tilly")

const THEME = {
	["color-primary"] = Color3.fromHex("79B8FF"),
	-- add more tokens as you go
}

return Tilly.new(THEME)
```

:::

## Add tag function

To make tagging instances more ergonomic, we're going to create a `tag.luau` module that returns a convenient `tag()` function.

If you're using a library like Fusion or Vide, this is especially helpful and allows for tags to be applied reactively.

::: code-group

```luau [No framework]
const myTilly = require("@src/myTilly")

return myTilly.addTags
```

```luau [Vide]
const Tilly = require("@packages/tilly")
const vide = require("@packages/vide")
const myTilly = require("@src/myTilly")

vide.defaults = false -- disables default properties that interfere with our styling

const function tag<Tags>(tags: Tilly.TagsInput<typeof(myTilly:getTokens()), Tags>)
	return vide.action(function(instance)
		if type(tags) == "string" then
			myTilly:addTags(instance, tags)
			return
		end

		if type(tags) == "function" then
			local removeTags: (() -> ())? = nil
			vide.effect(function()
				if removeTags ~= nil then
					removeTags()
					removeTags = nil
				end
				removeTags = myTilly:addTags(instance, (tags :: any)() :: "")
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

:::
