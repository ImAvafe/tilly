# CLAUDE.md

Tilly is a Tailwind-style utility tag library for Roblox UI. It runs entirely at runtime: `tag(instance, "bg-red-500 px-4 hover:bg-red-400")` adds sanitized CollectionService tags to the instance and lazily creates one `StyleRule` per tag (cached) in a user-supplied `StyleSheet`. See `README.md` for usage and `design.md` for goals.

## Tooling

Tools are managed by Rokit (`rokit.toml`): lune, rojo, stylua, rodeo, wally, luau-lsp.

All scripts in `scripts/` are run with **Lune**, except `scripts/test.luau`, `scripts/bench.luau` and `scripts/generateTags.luau`:

- `lune run scripts/dev` kills any running rojo, then runs `rojo sourcemap --watch` and `rojo serve` on `default.project.json`.
- `lune run scripts/studio` opens `testPlace.rbxl` in Studio through rodeo.
- `scripts/test.luau` is **not** a Lune script. Run it in Studio through the **Studio MCP**. It requires its siblings with `script.Parent` and `./tokens`, `./patterns`, etc., so it must run as a ModuleScript that is a child of the Tilly module (`ReplicatedStorage.tilly` under `default.project.json`). Create it there with the contents of `scripts/test.luau`, then run `require(game.ReplicatedStorage.tilly.test)()` (it takes an optional `Options` table and returns a `Report`). The usage comment in the file names a different path (Avalog vendor); ignore that.
- `scripts/generateTags.luau` builds every tag the patterns and tokens allow, for both the tests and the benchmarks. Create it as `ReplicatedStorage.tilly.generateTags` alongside them.
- `scripts/bench.luau` is also **not** a Lune script and is set up the same way, as `ReplicatedStorage.tilly.bench`. Run it on a fresh clone of `tilly` (Studio caches required modules and would time stale code), as the doc comment on `runBench` shows. A run takes about 7 seconds. Run it once per `execute_luau` call with an `operation_id`, and wait on `get_request_status` if the call times out instead of starting another: two back-to-back runs in one call froze Studio. It returns a report whose `json` is saved to `.bench/<commit>.json` (gitignored, and only valid on the same machine) and passed back as `baseline` to compare runs.

Format with `stylua src scripts`. `src` uses `--!strict` through `.luaurc`. `scripts/.luaurc` disables type checking and lint for scripts.

`dev.project.json` is a leftover from another project (Sculpt) and doesn't apply here.

## Architecture (`src/`)

- `init.luau`: the `tilly(styleSheet, tokens?)` entry point. Merges user tokens over the defaults, creates the property-default rules (priority -1), and returns `addTags(instance, tags) -> cleanup` and `destroy()`. It also holds `addCompositeRules`, which creates a compound-selector rule (`.tagA.tagB`) when two or more tags on an instance set components of the same composite property.
- `resolveTag.luau`: parses a tag into variants (`hover:`, `active:`, `disabled:`, `*:`, `**:`), an `!` importance suffix, and a utility. It finds the longest matching prefix in `patterns` and resolves the value against tokens, giving a `Rule` (selector, properties, priority, optional `component`). The priority is `100` if the tag is important, plus `10` per variant, plus a specificity term.
- `patterns.luau`: maps a utility prefix (`bg`, `text`, `rounded`, `w`, ...) to a list of `Pattern`s, which are tried in order. A `Pattern` names a token `namespace`, target `properties`, and optionally `manualProperties`, a `pseudoInstance` (such as `UIPadding`), a `propertyComponent` (it sets one component of a composite such as `Size.X` or `FontFace.Weight`), and `subtokens`.
- `tokens/*.luau` (besides `init.luau`) each return one `SCREAMING_SNAKE_CASE` table of kebab-case keys `{namespace}-{value}`. A bare `{namespace}` key is a base multiplier, as with `spacing = 4` for `p-4`. Subtokens use `--`, as in `shadow-lg--blur-1` and `ease-out--direction`. A new namespace must be required and added to the list in `tokens/init.luau`.
- `types.luau`: the shared types (`Rule`, `Pattern`, `Tokens`, ...) and the type functions for tag autocompletion (`AutocompleteTags`, `WithTokens`, `MergedTokensets`). `init.luau` re-exports the public ones.
- `util/propertyDefaults.luau`: the base properties per class, applied at priority -1.
- `util/`: `propertyDefaults`, `convertValue` (converts a raw token to the property's type, keyed by property name), `withComponents` (rebuilds a Font, UDim2, Vector2 or TweenInfo with some components replaced), `sanitizeTag` (makes a tag usable in a selector: `**`→`desc`, `*`→`child`, `!`→`_important`, `:`/`.`→`_`), and `mergeTokensets`.

The `.claude/` folder (gitignored) has research notes: `mappings.md` (Tailwind→Roblox mappings).

## Rules

- **Don't make architectural changes to Tilly's resolver** (`resolveTag`, the rule and composite machinery in `init.luau`, the `Pattern` shape) without explicit permission. If a feature needs one, stop and ask.
- Keep implementations minimal. Prefer adding patterns and tokens over adding new code paths.
- Follow the [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/).
- Naming: `PascalCase` for types and singletons, `SCREAMING_SNAKE_CASE` for constants, and `camelCase` for everything else (locals, functions, module files, and namespace file names).
- Use `const` for bindings that are never reassigned and `local` only when they are, matching the existing code.
- Use tab indentation, and keep call parentheses as written (stylua `call_parentheses = "Input"`).
- A table with two or more items goes one item per line. A single-item table or a short array of plain values (`{ "X", "Y" }`) can stay inline.
- No explainer comments. Only add a comment when it adds real value, such as a non-obvious reason or constraint the code can't show. No section-header comments or comments that restate the code.
- Document a function with a `--[[ ]]` multiline comment directly above its definition, so it shows in autocomplete. Don't use `--` line comments for function docs.
