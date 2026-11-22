# Theming

`Tilly.new()` accepts a `tokens` argument that takes in namespaced design tokens.

```luau
Tilly.new({
	["color-primary"] = Color3.fromHex("79B8FF"),
})
```

You can read the applied tokenset, including both default tokens and custom theme tokens, with `Tilly:getTokens()`. This can come in handy if you ever need to access native Roblox properties.
