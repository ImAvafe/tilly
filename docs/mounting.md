# Mounting your UI

For Tilly's styling to apply to a `ScreenGui` and its descendants, it first needs to be mounted with `Tilly:mount()`. Here's an example:

```luau
const Players = game:GetService("Players")

const myTilly = require("@src/myTilly")
const tag = require("@src/tag")

const screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer.PlayerGui
const button = Instance.new("TextButton")
button.Parent = screenGui

myTilly:mount(screenGui)

tag(button, "text-white bg-primary hover:opacity-10 px-4 py-3 rounded-lg border border-primary-hover")
```

You can also mount to `BillboardGui`s and `SurfaceGui`s.
