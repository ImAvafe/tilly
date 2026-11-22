# Utility tags

Utility tags are the core idea of Tilly, allowing you to apply complex styling with minimal markup. Let's break it down.

Utility tags contain several components: a **[prefix](#prefixes)**, the **[value](#value-types)** it ingests, and optionally **[variants](#variants)** and an [exclamation mark](#importance). The formatting is like so: `{variants}:{prefix}-{value}{!}`.

## Value types

Values are passed into utility tags to give them form, like how the `bg` prefix accepts tokens in the `color` namespace. Values can be of the following types, depending on the utility tag's prefix.

| Form                | Resolves to                                                | Examples                                                        |
| ------------------- | ---------------------------------------------------------- | --------------------------------------------------------------- |
| Token value         | `{namespace}-{value}`                                      | `rounded-lg` → `radius-lg`                                      |
| Multiplier          | base `{namespace}` token × the number (integer or decimal) | `p-4` → `4 × 4`, `p-0.5` → `0.5 × 4`, `opacity-50` → `50 / 100` |
| `px`                | the `{namespace}-px` token if there is one, else base × 1  | `p-px` → `spacing-px` (`1`)                                     |
| None (one-part tag) | `{namespace}-default`                                      | `border` → `border-default`                                     |
| Subtokens           | `{namespace}-{value}--{subtoken}-1` for each subtoken      | `shadow-lg` → `shadow-lg--offset-1`, `shadow-lg--blur-1`, …     |

## Variants

Variants make utility tags conditional, so the tag applies when the variant target is met.

| Variant     | Targets                               | Priority | Examples              |
| ----------- | ------------------------------------- | -------- | --------------------- |
| `hover:`    | `Enum.GuiState.Hover` state           | +10      | `hover:bg-red-400`    |
| `active:`   | `Enum.GuiState.Press` state           | +10      | `active:bg-red-600`   |
| `disabled:` | `Enum.GuiState.NonInteractable` state | +10      | `disabled:opacity-50` |
| `*:`        | Child instances                       | +10      | `*:p-2`               |
| `**:`       | Descendant instances                  | +10      | `**:text-white`       |

## Importance

By appending an exclamation mark `!` to the end of your tag, you give it priority to win out against other tags. This can be useful in resolving styling conflicts.

## Prefixes

Prefixes can be thought of as the "root" of a utility tag, defining its purpose and the properties it sets.

### Background

| Prefix    | Namespaces, in order | Sets                                                             | Examples                 |
| --------- | -------------------- | ---------------------------------------------------------------- | ------------------------ |
| `bg`      | `color` → `object`   | `BackgroundColor3` (+ `BackgroundTransparency = 0`); `ScaleType` | `bg-red-500`, `bg-cover` |
| `opacity` | `opacity`            | `Transparency`                                                   | `opacity-50`             |
| `object`  | `object`             | `ScaleType`                                                      | `object-contain`         |

### Typography

| Prefix       | Namespaces, in order                                               | Sets                                                                      | Examples                                                               |
| ------------ | ------------------------------------------------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `text`       | `text` → `color` → `text-align` → `text-wrapped` → `text-truncate` | `TextSize`; `TextColor3`; `TextXAlignment`; `TextWrapped`; `TextTruncate` | `text-lg`, `text-red-500`, `text-center`, `text-wrap`, `text-ellipsis` |
| `font`       | `font` → `font-weight`                                             | `FontFace.Family`; `FontFace.Weight`                                      | `font-mono`, `font-bold`                                               |
| `leading`    | `leading`                                                          | `LineHeight`                                                              | `leading-tight`                                                        |
| `align`      | `align`                                                            | `TextYAlignment`                                                          | `align-middle`                                                         |
| `truncate`   | `text-truncate`                                                    | `TextTruncate`                                                            | `truncate`, `truncate-clip`                                            |
| `whitespace` | `whitespace`                                                       | `TextWrapped`                                                             | `whitespace-nowrap`                                                    |

### Border and shadow

| Prefix   | Namespaces, in order | Sets                                                                                                              | Examples                                   |
| -------- | -------------------- | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| `border` | `border` → `color`   | `UIStroke.Thickness`; `UIStroke.Color`                                                                            | `border`, `border-2`, `border-red-500`     |
| `shadow` | `shadow` → `color`   | `UIShadow.Enabled`, or `Offset`, `BlurRadius`, `Spread`, `Color`, `Transparency` from subtokens; `UIShadow.Color` | `shadow-lg`, `shadow-none`, `shadow-black` |

### Corner radius

Every `rounded*` prefix uses only `radius` and sets `UICorner` properties. Logical prefixes assume LTR.

| Prefix       | Namespaces, in order | Sets                                                                       | Examples                     |
| ------------ | -------------------- | -------------------------------------------------------------------------- | ---------------------------- |
| `rounded`    | `radius`             | `TopLeftRadius`, `TopRightRadius`, `BottomRightRadius`, `BottomLeftRadius` | `rounded-lg`, `rounded-full` |
| `rounded-t`  | `radius`             | `TopLeftRadius`, `TopRightRadius`                                          | `rounded-t-md`               |
| `rounded-r`  | `radius`             | `TopRightRadius`, `BottomRightRadius`                                      | `rounded-r-md`               |
| `rounded-b`  | `radius`             | `BottomRightRadius`, `BottomLeftRadius`                                    | `rounded-b-md`               |
| `rounded-l`  | `radius`             | `TopLeftRadius`, `BottomLeftRadius`                                        | `rounded-l-md`               |
| `rounded-tl` | `radius`             | `TopLeftRadius`                                                            | `rounded-tl-xl`              |
| `rounded-tr` | `radius`             | `TopRightRadius`                                                           | `rounded-tr-xl`              |
| `rounded-br` | `radius`             | `BottomRightRadius`                                                        | `rounded-br-xl`              |
| `rounded-bl` | `radius`             | `BottomLeftRadius`                                                         | `rounded-bl-xl`              |
| `rounded-s`  | `radius`             | `TopLeftRadius`, `BottomLeftRadius`                                        | `rounded-s-lg`               |
| `rounded-e`  | `radius`             | `TopRightRadius`, `BottomRightRadius`                                      | `rounded-e-lg`               |
| `rounded-ss` | `radius`             | `TopLeftRadius`                                                            | `rounded-ss-sm`              |
| `rounded-se` | `radius`             | `TopRightRadius`                                                           | `rounded-se-sm`              |
| `rounded-ee` | `radius`             | `BottomRightRadius`                                                        | `rounded-ee-sm`              |
| `rounded-es` | `radius`             | `BottomLeftRadius`                                                         | `rounded-es-sm`              |

### Padding and gap

Logical prefixes assume LTR.

| Prefix  | Namespaces, in order | Sets                                                                   | Examples      |
| ------- | -------------------- | ---------------------------------------------------------------------- | ------------- |
| `p`     | `spacing`            | `UIPadding.PaddingTop`, `PaddingRight`, `PaddingBottom`, `PaddingLeft` | `p-4`, `p-px` |
| `px`    | `spacing`            | `UIPadding.PaddingLeft`, `PaddingRight`                                | `px-6`        |
| `py`    | `spacing`            | `UIPadding.PaddingTop`, `PaddingBottom`                                | `py-2`        |
| `pt`    | `spacing`            | `UIPadding.PaddingTop`                                                 | `pt-1`        |
| `pr`    | `spacing`            | `UIPadding.PaddingRight`                                               | `pr-1`        |
| `pb`    | `spacing`            | `UIPadding.PaddingBottom`                                              | `pb-1`        |
| `pl`    | `spacing`            | `UIPadding.PaddingLeft`                                                | `pl-1`        |
| `ps`    | `spacing`            | `UIPadding.PaddingLeft`                                                | `ps-3`        |
| `pe`    | `spacing`            | `UIPadding.PaddingRight`                                               | `pe-3`        |
| `pbs`   | `spacing`            | `UIPadding.PaddingTop`                                                 | `pbs-3`       |
| `pbe`   | `spacing`            | `UIPadding.PaddingBottom`                                              | `pbe-3`       |
| `gap`   | `spacing`            | `UIListLayout.Padding`                                                 | `gap-2`       |
| `gap-x` | `spacing`            | `UIListLayout.Padding`                                                 | `gap-x-2`     |
| `gap-y` | `spacing`            | `UIListLayout.Padding`                                                 | `gap-y-2`     |

### Sizing

Logical prefixes assume a horizontal writing mode.

| Prefix       | Namespaces, in order                 | Sets                                  | Examples                   |
| ------------ | ------------------------------------ | ------------------------------------- | -------------------------- |
| `w`          | `spacing` → `container` → `fraction` | `Size.X`                              | `w-8`, `w-md`, `w-full`    |
| `h`          | `spacing` → `fraction`               | `Size.Y`                              | `h-8`, `h-full`            |
| `size`       | `spacing` → `fraction`               | `Size`                                | `size-10`, `size-full`     |
| `min-w`      | `spacing` → `container`              | `UISizeConstraint.MinSize.X`          | `min-w-16`, `min-w-sm`     |
| `min-h`      | `spacing`                            | `UISizeConstraint.MinSize.Y`          | `min-h-16`                 |
| `max-w`      | `spacing` → `container`              | `UISizeConstraint.MaxSize.X`          | `max-w-lg`                 |
| `max-h`      | `spacing`                            | `UISizeConstraint.MaxSize.Y`          | `max-h-64`                 |
| `inline`     | `spacing` → `container`              | `Size.X`                              | `inline-8`, `inline-md`    |
| `block`      | `spacing`                            | `Size.Y`                              | `block-8`                  |
| `min-inline` | `spacing` → `container`              | `UISizeConstraint.MinSize.X`          | `min-inline-sm`            |
| `min-block`  | `spacing`                            | `UISizeConstraint.MinSize.Y`          | `min-block-16`             |
| `max-inline` | `spacing` → `container`              | `UISizeConstraint.MaxSize.X`          | `max-inline-lg`            |
| `max-block`  | `spacing`                            | `UISizeConstraint.MaxSize.Y`          | `max-block-64`             |
| `aspect`     | `aspect`                             | `UIAspectRatioConstraint.AspectRatio` | `aspect-video`, `aspect-2` |
| `auto`       | `automatic-size`                     | `AutomaticSize`                       | `auto-xy`                  |

### Position and transform

Logical prefixes assume LTR.

| Prefix        | Namespaces, in order | Sets            | Examples                  |
| ------------- | -------------------- | --------------- | ------------------------- |
| `inset`       | `spacing`            | `Position`      | `inset-4`                 |
| `inset-x`     | `spacing`            | `Position.X`    | `inset-x-4`               |
| `inset-y`     | `spacing`            | `Position.Y`    | `inset-y-4`               |
| `top`         | `spacing`            | `Position.Y`    | `top-2`                   |
| `left`        | `spacing`            | `Position.X`    | `left-2`                  |
| `inset-s`     | `spacing`            | `Position.X`    | `inset-s-2`               |
| `inset-bs`    | `spacing`            | `Position.Y`    | `inset-bs-2`              |
| `translate`   | `spacing`            | `Position`      | `translate-2`             |
| `translate-x` | `spacing`            | `Position.X`    | `translate-x-2`           |
| `translate-y` | `spacing`            | `Position.Y`    | `translate-y-2`           |
| `scale`       | `scale`              | `UIScale.Scale` | `scale-150`, `scale-none` |
| `rotate`      | `rotate`             | `Rotation`      | `rotate-45`               |

### Image and scrolling

| Prefix            | Namespaces, in order | Sets                   | Examples                   |
| ----------------- | -------------------- | ---------------------- | -------------------------- |
| `fill`            | `color`              | `ImageColor3`          | `fill-white`               |
| `stroke`          | `color`              | `ImageColor3`          | `stroke-white`             |
| `scrollbar-thumb` | `color`              | `ScrollBarImageColor3` | `scrollbar-thumb-zinc-500` |

### Layout

| Prefix          | Namespaces, in order                                                                    | Sets                                                                                                                                                       | Examples                                        |
| --------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `flex`          | `fill-direction` → `flex-wrap` → `flex-mode`                                            | `UIListLayout.FillDirection`; `UIListLayout.Wraps`; `UIFlexItem.FlexMode`                                                                                  | `flex`, `flex-col`, `flex-wrap`, `flex-1`       |
| `grid`          | `fill-direction`                                                                        | `UIGridLayout.FillDirection`                                                                                                                               | `grid`, `grid-col`                              |
| `grid-flow`     | `fill-direction`                                                                        | `UIGridLayout.FillDirection`                                                                                                                               | `grid-flow-col`                                 |
| `grid-cols`     | `max-cells`                                                                             | `UIGridLayout.FillDirectionMaxCells` (+ `FillDirection = Horizontal`)                                                                                      | `grid-cols-3`                                   |
| `grid-rows`     | `max-cells`                                                                             | `UIGridLayout.FillDirectionMaxCells` (+ `FillDirection = Vertical`)                                                                                        | `grid-rows-2`                                   |
| `grow`          | `grow`                                                                                  | `UIFlexItem.FlexMode = Grow`                                                                                                                               | `grow`                                          |
| `shrink`        | `shrink`                                                                                | `UIFlexItem.FlexMode = Shrink`                                                                                                                             | `shrink`                                        |
| `justify`       | `horizontal-alignment` → `flex-alignment`                                               | `UIListLayout.HorizontalAlignment` (+ `HorizontalFlex = None`); `UIListLayout.HorizontalFlex`                                                              | `justify-center`, `justify-between`             |
| `content`       | `vertical-alignment` → `flex-alignment`                                                 | `UIListLayout.VerticalAlignment` (+ `VerticalFlex = None`); `UIListLayout.VerticalFlex`                                                                    | `content-end`, `content-evenly`                 |
| `place-content` | `place-content-start` → `place-content-center` → `place-content-end` → `flex-alignment` | `UIListLayout.HorizontalAlignment` (+ matching `VerticalAlignment`, both flexes `None`), once per alignment; `UIListLayout.HorizontalFlex`, `VerticalFlex` | `place-content-center`, `place-content-between` |
| `items`         | `item-alignment`                                                                        | `UIListLayout.ItemLineAlignment`                                                                                                                           | `items-center`                                  |
| `place-items`   | `item-alignment`                                                                        | `UIListLayout.ItemLineAlignment`                                                                                                                           | `place-items-center`                            |
| `self`          | `item-alignment`                                                                        | `UIFlexItem.ItemLineAlignment`                                                                                                                             | `self-end`                                      |
| `place-self`    | `item-alignment`                                                                        | `UIFlexItem.ItemLineAlignment`                                                                                                                             | `place-self-end`                                |
| `order`         | `order`                                                                                 | `LayoutOrder`                                                                                                                                              | `order-2`, `order-first`                        |
| `z`             | `z`                                                                                     | `ZIndex`                                                                                                                                                   | `z-10`                                          |

### Visibility and interaction

| Prefix           | Namespaces, in order | Sets               | Examples                              |
| ---------------- | -------------------- | ------------------ | ------------------------------------- |
| `hidden`         | `hidden`             | `Visible = false`  | `hidden`                              |
| `visible`        | `visible`            | `Visible = true`   | `visible`                             |
| `overflow`       | `overflow`           | `ClipsDescendants` | `overflow-hidden`, `overflow-visible` |
| `pointer-events` | `pointer-events`     | `Interactable`     | `pointer-events-none`                 |

### Transitions

These set the default transition (`*`), which applies to every property.

| Prefix       | Namespaces, in order | Sets                                        | Examples                        |
| ------------ | -------------------- | ------------------------------------------- | ------------------------------- |
| `transition` | `duration`           | `TweenInfo.Time`                            | `transition`, `transition-300`  |
| `duration`   | `duration`           | `TweenInfo.Time`                            | `duration-300`, `duration-none` |
| `ease`       | `ease`               | `TweenInfo.EasingStyle` + `EasingDirection` | `ease`, `ease-out`              |
| `delay`      | `delay`              | `TweenInfo.DelayTime`                       | `delay-150`                     |
