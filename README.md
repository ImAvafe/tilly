# Tilly -  Tailwind for Roblox

Tilly is a port of Tailwind's functionality and syntax to Roblox stylesheets. Minimize your markup without learning another format.

> [!IMPORTANT]
> Tilly is not stable or mature enough for use in production! Implementation will change frequently as it approaches maturity.

## [Get started](https://avafe.me/tilly/start)

## [How it works](https://avafe.me/tilly/explainer)

## Example

Here's what using Tilly within a component structure looks like.

```luau
const style = require("@src/style")
const new = require("@packages/new") -- pretend this is your favorite reactivity library

const tag = style.tag

return function()
	return new "TextButton" {
		tag("text-white bg-primary hover:bg-primary-hover px-4 py-3 rounded-lg border border-primary-hover")
	}
end
```

## Tailwind parity

Tilly aims for its coverage and syntax to be as close as possible to Tailwind. You can find a complete reference of Tailwind's utilities here: https://tailwindcss.com/docs/. There are bound to be gaps and errors in the existing utility definitions. If you spot one, submit a PR!
