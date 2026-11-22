# Tilly - Tailwind for Roblox

Tilly is a port of Tailwind's functionality and syntax to Roblox stylesheets. Minimize your markup without learning another format.

## [Get started](https://avafe.me/tilly/start)

## [How it works](https://avafe.me/tilly/explainer)

## Example

Here's what using Tilly within a component structure looks like.

```luau
const tag = require("@src/tag")
const new = require("@packages/new") -- pretend this is your favorite reactivity library

return function()
	return new "TextButton" {
		tag("text-white bg-primary hover:bg-primary-hover px-4 py-3 rounded-lg border border-primary-hover")
	}
end
```

## Tailwind parity

Tilly aims for its coverage and syntax to be as close as possible to Tailwind. You can find a complete reference of Tailwind's utilities here: https://tailwindcss.com/docs/. There are bound to be gaps and errors in the existing utility definitions. If you spot one, submit a PR!
