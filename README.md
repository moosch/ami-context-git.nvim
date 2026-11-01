# ami-context-git.nvim

Feed your **uncommitted git diff** to [ami](https://github.com/moosch/ami.nvim) as
extra context, so the advisor sees what you're actually changing — not just the saved
file.

It's a **context-provider** extension: it contributes to ami's `context.extra`
collector, which the chat advisor (and proactive nudges) fold into the context they
send. It's the reference example of that pattern.

## Requirements

- [ami.nvim](https://github.com/moosch/ami.nvim) (+ a feature that uses context, e.g.
  [ami-chat.nvim](https://github.com/moosch/ami-chat.nvim)).
- `git` on `PATH`.

## Install

```lua
{
  "moosch/ami.nvim",
  dependencies = { "moosch/ami-chat.nvim", "moosch/ami-context-git.nvim" },
  config = function()
    require("ami").setup({
      extensions = { require("ami-chat"), require("ami-context-git") },
      -- context_git = { max_bytes = 4000, timeout_ms = 2000 },
    })
  end,
}
```

## What it adds

On each turn, if the project is a git repo with uncommitted changes, it adds a
section to ami's context:

```
## Uncommitted changes (git diff vs HEAD)
```
diff --git a/store.go b/store.go
@@ ...
-func Get() {}
+func Get(id string) (*User, error) { ... }
```
```

A clean tree contributes nothing (no noise). The diff is capped to `max_bytes`.

## Configuration

Config lives under `context_git` in ami's `setup()`:

| Key | Default | Meaning |
| --- | --- | --- |
| `max_bytes` | `4000` | cap the diff size sent (keeps the context budget sane) |
| `timeout_ms` | `2000` | max time to wait for `git` per turn |

## Notes

The diff is gathered **synchronously** (a quick `git diff`) during context assembly,
so keep `max_bytes`/`timeout_ms` modest on very large repos. Writing your own context
provider is the same shape — register `api.on("context.extra", fn)` and return a
`{ title, body }` (or a string, or `nil`); see ami's
[`docs/extensions.md`](https://github.com/moosch/ami.nvim/blob/main/docs/extensions.md).

## License

[MIT](LICENSE)
