# How it works

Here's how Tilly ports the functionality and syntax of Tailwind to Roblox stylesheets.

Tilly maintains two sets of definitions: **namespaced tokens** and **utility patterns**. Tokens are fed into utilities that accept them, which is how `bg-red-500` and `text-red-500` both source from the `color-red-500` token.

A major difference between Tilly and Tailwind is where they operate: Tilly operates at runtime and renders into `StyleRule`s, while Tailwind is a build tool and compiles into `CSS`.

Implementing Tilly as a build tool would yield marginally better performance while complicating integration with libraries like Vide or Fusion and entirely neglecting Roblox Studio users.

Tilly has alleviated these performance concerns by lazily resolving utility tags. Tags are only ever resolved and rendered into `StyleRule`s when they're applied, and then they're preserved for reuse.

Although Tilly resolves tags at runtime, most of its processing time concerns the construction of `StyleRule`s themselves, which would also apply to a build tool.
