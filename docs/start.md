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

## Integration

To use Tilly effectively, I'd recommend this boilerplate structure to start. The rest of the guides assume this structure.

For Roblox Studio users: `.luau` files are child `ModuleScript`s. `style` is also a `ModuleScript`. The `init.luau` file's code should be placed within `styling`.

::: code-group

```[File structure]
- style
	- styleSheet.luau
	- tokens.luau
	- tag.luau
	- init.luau
```

:::

::: code-group

```luau [styleSheet.luau]
return Instance.new("StyleSheet")
```

```luau [tokens.luau]
const defaultTokens = require("@src/vendor/tilly/tokens")
const mergeTokensets = require("@src/vendor/tilly/util/mergeTokensets")

const THEME = {
	["color-primary"] = Color3.fromHex("79B8FF"),
	-- add more tokens as you go
}

return mergeTokensets({ defaultTokens, THEME })
```

```luau [tag.luau]
const tilly = require("@packages/tilly")
const styleSheet = require("@src/style/styleSheet")
const tokens = require("@src/style/tokens")

return tilly(styleSheet, tokens) -- returns addTags(), destroy()
```

```luau [init.luau]
const styleSheet = require("@src/style/styleSheet")
const tokens = require("@src/style/tokens")
const tag = require("@src/style/tag")

return {
	styleSheet = styleSheet,
	tokens = tokens,
	tag = tag,
}
```

:::
