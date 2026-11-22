# Patterns ↔ tokens map

How `src/patterns.luau` (utility prefixes) and `src/tokens/*.luau` (namespaces) connect.

## How a tag reaches a token

1. `resolveTag` splits the utility on `-` and tries the **longest prefix** in `PATTERNS` first (`rounded-tl-lg` → `rounded-tl` + `lg`).
2. Each pattern under that prefix is tried **in order**. The first one that resolves wins.
3. A pattern resolves `value` against its `namespace` in this order:
    - the token `{namespace}-{value}` (`radius-lg`)
    - the bare `{namespace}` token × a numeric value or `px` (`spacing` × `4` for `p-4`)
    - subtokens `{namespace}-{value}--{subtoken}-1` (`shadow-lg--blur-1`)
4. A one-part tag (`border`, `hidden`) resolves with the value `default` (`border-default`, `hidden-default`).
5. `manualProperties` are added on top of whatever the token set.

The resolver also reads some tokens directly by name to build composite bases (`compositeBase`):
`font-sans`, `font-weight-normal` (FontFace), `duration-default`, `ease-default` and `ease-default--direction` (the `*` TweenInfo).

## Utility tags

When a prefix has several namespaces, **Sets** lists what each one sets, in the same order, separated by `;`. Properties in parentheses come from `manualProperties`.

## Selectors

A rule's selector is `.{sanitized tag}{combinator}{:GuiState…}{::pseudoInstance}`.

| Tag                    | Selector                                              |
| ---------------------- | ----------------------------------------------------- |
| `bg-red-500`           | `.bg-red-500`                                         |
| `p-4`                  | `.p-4::UIPadding`                                     |
| `hover:bg-red-400`     | `.hover_bg-red-400:Hover`                             |
| `*:rounded-md`         | `.child_rounded-md > GuiObject::UICorner`             |
| `**:hover:text-white!` | `.desc_hover_text-white_important >> GuiObject:Hover` |

### Tag sanitizing

`sanitizeTag` rewrites the tag before it's added to the instance and used in the selector. The replacements run in this order.

| Character | Becomes      | Examples                  |
| --------- | ------------ | ------------------------- |
| `**`      | `desc`       | `**:p-2` → `desc_p-2`     |
| `*`       | `child`      | `*:p-2` → `child_p-2`     |
| `!`       | `_important` | `p-2!` → `p-2_important`  |
| `:`       | `_`          | `hover:p-2` → `hover_p-2` |
| `.`       | `_`          | `p-0.5` → `p-0_5`         |

### Pseudo-instances

Patterns with a `pseudoInstance` style a child modifier through `::{Class}`. The StyleSheet creates the modifier, so it doesn't need to exist.

| Pseudo-instance           | Prefixes                                                                                                         |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `UIPadding`               | `p`, `px`, `py`, `pt`, `pr`, `pb`, `pl`, `ps`, `pe`, `pbs`, `pbe`                                                |
| `UIListLayout`            | `gap`, `gap-x`, `gap-y`, `flex` (direction, wrap), `items`, `place-items`, `justify`, `content`, `place-content` |
| `UIGridLayout`            | `grid`, `grid-flow`, `grid-cols`, `grid-rows`                                                                    |
| `UIFlexItem`              | `flex` (mode), `grow`, `shrink`, `self`, `place-self`                                                            |
| `UICorner`                | all 15 `rounded*` prefixes                                                                                       |
| `UIStroke`                | `border`                                                                                                         |
| `UIShadow`                | `shadow`                                                                                                         |
| `UISizeConstraint`        | `min-*`, `max-*` (width, height, inline, block)                                                                  |
| `UIAspectRatioConstraint` | `aspect`                                                                                                         |
| `UIScale`                 | `scale`                                                                                                          |

## Priority

`StyleRule.Priority` decides which rule wins when two set the same property.

| Source            | Priority                                                       |
| ----------------- | -------------------------------------------------------------- |
| Property defaults | -1                                                             |
| Specificity       | `4 - #properties`, +1 if the value isn't `default` (range 0–4) |
| Each variant      | +10                                                            |
| Importance (`!`)  | +100                                                           |
| Composite rule    | highest priority among its tags + 1                            |

Specificity makes narrower tags win over broader ones on the same element:

| Tag          | Properties | Value     | Priority |
| ------------ | ---------- | --------- | -------- |
| `p-4`        | 4          | number    | 1        |
| `px-2`       | 2          | number    | 3        |
| `pl-1`       | 1          | number    | 4        |
| `border`     | 1          | `default` | 3        |
| `border-2`   | 1          | number    | 4        |
| `hover:pl-1` | 1          | number    | 14       |
| `pl-1!`      | 1          | number    | 104      |

## Composite properties

Some patterns set one component of a composite value through `propertyComponent`. When two or more tags on the same instance set components of the same property with the same selector suffix (variants and pseudo-instance), `_addCompositeRules` creates a compound rule like `.font-mono.font-bold`. The tag names are sorted case-insensitively, and the components are merged in priority order, so a higher-priority tag wins. The compound rule is rebuilt when tags are added and when the cleanup function runs.

| Property        | Components                                             | Base value                                                               | Prefixes                                                                                 |
| --------------- | ------------------------------------------------------ | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `FontFace`      | `Family`, `Weight`                                     | `Font.new(font-sans, font-weight-normal)`                                | `font`                                                                                   |
| `Size`          | `X`, `Y`                                               | `UDim2.new()`                                                            | `w`, `h`, `inline`, `block`                                                              |
| `Position`      | `X`, `Y`                                               | `UDim2.new()`                                                            | `inset-x`, `inset-y`, `top`, `left`, `inset-s`, `inset-bs`, `translate-x`, `translate-y` |
| `MinSize`       | `X`, `Y`                                               | `Vector2.zero`                                                           | `min-w`, `min-h`, `min-inline`, `min-block`                                              |
| `MaxSize`       | `X`, `Y`                                               | `Vector2.new(math.huge, math.huge)`                                      | `max-w`, `max-h`, `max-inline`, `max-block`                                              |
| `*` (TweenInfo) | `Time`, `EasingStyle` + `EasingDirection`, `DelayTime` | `TweenInfo.new(duration-default, ease-default, ease-default--direction)` | `transition`, `duration`, `ease`, `delay`                                                |

`size`, `inset` and `translate` set the whole value, so they aren't merged with the per-axis tags.

## Value conversion

`convertValue` turns a raw token into the property's type, keyed by property name. Every other property takes the token as is.

| Properties                                                                              | Conversion                                                                   |
| --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `Padding`, `PaddingTop`/`Right`/`Bottom`/`Left`, `HorizontalPadding`, `VerticalPadding` | `UDim.new(0, n)`                                                             |
| `CornerRadius`, `TopLeftRadius`/`TopRightRadius`/`BottomRightRadius`/`BottomLeftRadius` | `UDim.new(0, n)`                                                             |
| `BlurRadius`                                                                            | `UDim.new(0, n)`                                                             |
| `Size`, `Position`, `Spread`                                                            | `UDim2.fromOffset(n, n)` (a `UDim2` token passes through)                    |
| `Offset`                                                                                | `UDim2.fromOffset(v.X, v.Y)` from a `Vector2`                                |
| `MinSize`, `MaxSize`                                                                    | `Vector2.new(n, n)`                                                          |
| `Transparency`                                                                          | clamped to 0–1                                                               |
| `FontFace`                                                                              | `Font.new(family)` from a string, `Font.new("", weight)` from a `FontWeight` |

A `TweenInfo` value is applied with `SetPropertyTransition` instead of `SetProperty`.

## Property defaults

`util/propertyDefaults.luau` creates one rule per class selector at priority -1 when Tilly is constructed.

| Class                                | Properties                                                                                                                                    |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `GuiObject`                          | `AutomaticSize = XY`, `BorderSizePixel = 0`, `BorderMode = Inset`, `BackgroundTransparency = 1`                                               |
| `GuiButton`                          | `AutoButtonColor = false`                                                                                                                     |
| `TextLabel`, `TextButton`, `TextBox` | `FontFace` (`font-sans`, `font-weight-normal`), `TextSize = text-base`, `TextWrapped = true`, `TextXAlignment = Left`, `TextYAlignment = Top` |
| `TextBox`                            | also `ClearTextOnFocus = false`                                                                                                               |
| `ImageLabel`, `ImageButton`          | `ScaleType = Fit`                                                                                                                             |
| `UIListLayout`                       | `SortOrder = LayoutOrder`                                                                                                                     |
| `UIStroke`                           | `ApplyStrokeMode = Border`, `BorderStrokePosition = Inner`                                                                                    |
| `UICorner`                           | all four corner radii `0`                                                                                                                     |
| `UIShadow`                           | `Color = color-black`                                                                                                                         |

## API

| Member                     | Does                                                                                                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Tilly.new(tokens?)`       | Creates a `StyleSheet` named `Tilly` in `ReplicatedStorage`, merges `tokens` over the defaults, and adds the property-default rules                                                         |
| `:addTags(instance, tags)` | Splits `tags` on spaces, adds each sanitized tag to the instance, resolves and caches one `StyleRule` per tag, and builds composite rules. Returns a cleanup function that removes the tags |
| `:mount(root)`             | Adds a `StyleLink` to `root` that points at the sheet. Returns an unmount function                                                                                                          |
| `:getTokens()`             | Returns the merged tokens                                                                                                                                                                   |
| `:destroy()`               | Destroys every `StyleLink` and the `StyleSheet`                                                                                                                                             |

Rules are cached by the raw tag. An invalid tag is cached as `false`, so it only warns once.

## Theming

| Change                     | How                                                   | Examples                                                    |
| -------------------------- | ----------------------------------------------------- | ----------------------------------------------------------- |
| Override a token           | Pass the same key to `Tilly.new`                      | `["color-red-500"] = Color3.fromHex("#ff0000")`             |
| Add a value to a namespace | Pass a new key in an existing namespace               | `["color-brand-500"]` → `bg-brand-500`, `text-brand-500`, … |
| Change a scale             | Override the base token                               | `["spacing"] = 8` makes `p-4` 32 px                         |
| Add a namespace            | Not possible through tokens: no pattern would read it | —                                                           |

## Autocomplete

`AutocompleteTags` (in `types.luau`) completes the last word of the tag string.

| Suggests                                      | When                                                     |
| --------------------------------------------- | -------------------------------------------------------- |
| `hover:`, `active:`, `disabled:`, `*:`, `**:` | the word is a prefix of a variant not already used in it |
| Token keys                                    | the word is a prefix of a key in the merged tokens       |

## Gaps and quirks

- **Unused tokens:** all of `breakpoint`, `inset-shadow` and `text-shadow`; the `text-*--line-height` subtokens (the `text` pattern has no `subtokens`); and shadow layers `-2` and `-3` (the resolver only reads `--{subtoken}-1`).
- **Two subtoken formats:** `shadow` uses `--{subtoken}-1` (resolved in `resolveProperties`), while `ease` uses `--{subtoken}` with no layer (resolved in the `propertyComponent` branch).
- **One-part tags:** a bare `text` resolves to `text-truncate-default`, because it's the only `default` key under `text`. Bare `rounded` and `shadow` don't resolve, since there's no `radius-default` or `shadow-default`.
- **Long namespaces reachable through a shorter one:** a namespace is joined to the value, so `text-align-center` is matched by the `text` namespace as the key `text-align-center` and sets `TextSize` to an enum. The same goes for `text-wrapped-*`, `text-truncate-*` and `font-weight-*` (through `font`).
- **`opacity` sets `Transparency` directly:** `opacity-25` gives `Transparency = 0.25` (75% opaque), the opposite of Tailwind.
- **`container` is X only:** it isn't on `h`, `block`, `min-h` or `max-h`.
- **`gap-x` and `gap-y`** both set the same `UIListLayout.Padding`.
- **Position:** `inset`, `inset-*`, `top`, `left` and `translate*` all write `Position`, so `translate` replaces an inset instead of adding to it. There's no `right` or `bottom`.
- **`place-content` namespaces:** each of `start`, `center` and `end` is its own namespace so its pattern can set a matching `VerticalAlignment` through `manualProperties`. That's why the keys are doubled (`place-content-center-center`).
- **Property defaults ignore the theme:** `propertyDefaults` reads the default `tokens` module, not the merged tokens. Overriding `font-sans` or `text-base` doesn't change the base `TextLabel` style. `compositeBase` does use the merged tokens.
- **Autocomplete suggests token keys, not tags:** typing `bg-` doesn't complete to `bg-red-500`. The suggestions are keys like `color-red-500`.
- **Unknown variants are silent:** `focus:bg-red-500` resolves, adds +10 priority, and applies all the time.
- **Repeated spaces** in the tag string produce an empty tag, which is added to the instance and fails to resolve without a warning.
