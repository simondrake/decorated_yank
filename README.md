<div align="center">

# Decorated Yank
##### Yank code with context: file names, line numbers, git links, and treesitter metadata.

</div>

## Features

- **Decorated yank** -- yank visual selection with file name and line numbers
- **Decorated yank with link** -- same as above, plus a permalink to the code on GitHub/GitLab and treesitter context (function name, type name, etc.)
- **Blame link** -- copy a blame URL for the visual selection to the clipboard
- **Browse** -- open the current file (or visual selection) in the browser on GitHub/GitLab

All links use the commit hash so they remain stable even as the branch moves. Git worktrees are fully supported.

## Requirements

- Neovim 0.10+
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

```lua
-- lazy.nvim
{
  "simondrake/decorated_yank",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    domains = {
      github = {
        url = "github.com",
        blob = "/blob/",
        blame = "/blame/",
        line_format = "#L%s-L%s",
      },
    },
  },
}
```

## Configuration

You need to configure at least one domain so the plugin knows how to build URLs. Each domain entry has:

| Key | Description | Example (GitHub) | Example (GitLab) |
|---|---|---|---|
| `url` | Domain without scheme | `github.com` | `gitlab.example.com` |
| `blob` | Path segment for file views | `/blob/` | `/-/blob/` |
| `blame` | Path segment for blame views | `/blame/` | `/-/blame/` |
| `line_format` | Line range format string | `#L%s-L%s` | `#L%s-%s` |

```lua
require("decorated_yank").setup({
  domains = {
    github = {
      url = "github.com",
      blob = "/blob/",
      blame = "/blame/",
      line_format = "#L%s-L%s",
    },
    gitlab = {
      url = "gitlab.example.com",
      blob = "/-/blob/",
      blame = "/-/blame/",
      line_format = "#L%s-%s",
    },
  },
})
```

The domain key names (e.g. `github`, `gitlab`) are arbitrary -- the plugin matches on the `url` field against the git remote.

## Usage

### Decorated Yank

Yanks the visual selection with file name and line numbers. Works outside of git repos (links are omitted).

```lua
:'<,'>lua require("decorated_yank").decorated_yank()
```

Output copied to clipboard:

```
------------------------
file name: internal/notes/notes.go
------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```

### Decorated Yank with Link

Yanks the visual selection with file name, treesitter context, a permalink, and line numbers.

```lua
:'<,'>lua require("decorated_yank").decorated_yank_with_link()
```

Output copied to clipboard:

```
------------------------
file name: internal/notes/notes.go

type name: NoteReader

link: https://github.com/simondrake/copy-paste-notes/blob/9dc72ec/internal/notes/notes.go#L15-L19
------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```

Treesitter context is included when the cursor is inside a recognized node (`function_declaration`, `method_declaration`, or `type_spec`).

### Blame Link

Copies a blame URL for the visual selection to the system clipboard.

```lua
:'<,'>lua require("decorated_yank").blame_link()
```

Copies a URL like `https://github.com/simondrake/genc/blame/2e0754b/main.go#L6-L6`.

The raw URL string is also available via `blame_link_raw()` if you want to use it programmatically.

### Blame At

Opens a blame URL for a specific commit, file, and line in the browser. Designed for programmatic use by other plugins (e.g. [nvim-review](https://github.com/simondrake/nvim-review)).

```lua
-- Open blame in browser
require("decorated_yank").blame_at(hash, file, line, { cwd = "/path/to/repo" })

-- Get the URL as a string
local url = require("decorated_yank").blame_at_raw(hash, file, line, { cwd = "/path/to/repo" })
```

The `cwd` option specifies the git repository directory, which is important when the current buffer isn't inside the target repo (e.g. when called from a scratch buffer).

### Browse

Opens the current file in the browser on GitHub/GitLab. In normal mode it links to the file; in visual mode it includes the selected line range.

```lua
-- Open in browser
:lua require("decorated_yank").browse()

-- Copy the URL to clipboard instead
:lua vim.fn.setreg("+", require("decorated_yank").browse_link_raw())
```

## Example Keymaps and Commands

```lua
-- Decorated yank with link (visual mode)
vim.keymap.set("v", "<C-y>", function()
  require("decorated_yank").decorated_yank_with_link()
end)

-- Blame link to clipboard (visual mode)
vim.api.nvim_create_user_command("GBlame", function()
  require("decorated_yank").blame_link()
end, { range = true })

-- Open blame in browser (visual mode)
vim.api.nvim_create_user_command("GBlameO", function()
  vim.ui.open(require("decorated_yank").blame_link_raw())
end, { range = true })

-- Browse file in browser (normal + visual mode)
vim.api.nvim_create_user_command("GBrowse", function(opts)
  require("decorated_yank").browse({
    line1 = opts.range > 0 and opts.line1 or nil,
    line2 = opts.range > 0 and opts.line2 or nil,
  })
end, { range = true })

-- Copy browse link to clipboard (normal + visual mode)
vim.api.nvim_create_user_command("GBrowseY", function(opts)
  vim.fn.setreg("+", require("decorated_yank").browse_link_raw({
    line1 = opts.range > 0 and opts.line1 or nil,
    line2 = opts.range > 0 and opts.line2 or nil,
  }))
end, { range = true })
```

## API

| Function | Mode | Description |
|---|---|---|
| `decorated_yank()` | Visual | Yank selection with file name and line numbers |
| `decorated_yank_with_link()` | Visual | Yank selection with file name, treesitter context, and permalink |
| `blame_link()` | Visual | Copy blame URL to clipboard |
| `blame_link_raw()` | Visual | Return blame URL as a string |
| `blame_at(hash, file, line, opts?)` | Programmatic | Open blame URL in browser for a specific commit/file/line |
| `blame_at_raw(hash, file, line, opts?)` | Programmatic | Return blame URL as a string for a specific commit/file/line |
| `browse(opts?)` | Normal/Visual | Open file in browser (pass `line1`/`line2` for range) |
| `browse_link_raw(opts?)` | Normal/Visual | Return browse URL as a string (pass `line1`/`line2` for range) |
