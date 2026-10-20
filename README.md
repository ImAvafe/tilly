# Tilly

Like Tailwind, Tilly allows you to style your Roblox UI using utility tags and minimize your markup!

Unlike Tailwind, Tilly is not a build tool and instead operates entirely at runtime. To save on performance, it renders and caches only the tags applied.

>[!IMPORTANT]
>Tilly is not stable or mature enough for use in production! Implementation will change frequently as it approaches maturity.

## Installation

There are currently no releases available. Paste Tilly's `src` folder into your project to install it!

## Usage

```luau
const tilly = require(path.to.tilly)

const screenGui = Instance.new("ScreenGui")
const styleSheet = Instance.new("StyleSheet")
const styleLink = Instance.new"StyleLink")

screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
styleLink.StyleSheet = styleSheet
styleLink.Parent = screenGui
styleSheet.Parent = styleLink

const tag, destroy = tilly(styleSheet, {
	["color-primary"] = Color3.fromHex("#7245ff"),
	["color-primary-hover"] = Color3.fromHex("#8159FF")
	-- ...the rest of your theme tokens
})

const button = Instance.new("TextButton")
button.Parent = screenGui

tag(button, "text-white bg-primary hover:bg-primary-hover px-4 py-3 rounded-lg border border-primary-hover")
```

### With a reactivity library

If you're using a reactivity library to construct your UI, it's recommended to wrap Tilly's `tag()` function for your framework of choice. Below is an example of how that might look in Vide:

```luau
const function videTag(tags: string)
	return action(function(instance)
		tag(instance, tags)
	end)
end

create "TextButton" {
	videTag("text-white bg-indigo-500 hover:bg-indigo-400 px-4 py-3 rounded-lg border border-indigo-400")
}
```

## Tailwind parity

Tilly's syntax is identical to Tailwind for the utilities currently supported. You can find a complete reference of Tailwind's utilities here: https://tailwindcss.com/docs/

Some Tailwind features and utilities are currently blocked by limitations in Tilly's resolver. Among these are style queries, transitions, and composite properties. You can still define these in your markup without Tilly.

There are bound to be errors in the existing utility definitions. If you spot one, submit a PR! Porting tools to other engines is a process of maintenance.
