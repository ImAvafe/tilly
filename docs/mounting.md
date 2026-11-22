# Mounting your UI

For Tilly's styling to apply to a `ScreenGui` and its descendants, it first needs to be mounted with `Tilly:mount()`. Here's an example:

```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const myTilly = require("@src/myTilly")
const tag = require("@src/tag")

const screenGui = Instance.new("ScreenGui")
screenGui.Parent = ReplicatedStorage
const button = Instance.new("TextButton")
button.Parent = screenGui

myTilly:mount(screenGui)

tag(button, tag("text-white bg-primary hover:bg-primary-hover px-4 py-3 rounded-lg border border-primary-hover"))
```

Alongside `ScreenGui`s, you can also mount to `BillboardGui`s and `SurfaceGui`s.
