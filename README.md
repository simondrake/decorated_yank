<div align="center">

# Decorated Yank
##### Yank code with context: file names, line numbers, git links, and treesitter metadata.

</div>

## Features

- **Decorated yank** -- yank visual selection with file name and line numbers
- **Decorated yank with link** -- same as above, plus a permalink to the code on GitHub/GitLab and treesitter context (function name, type name, etc.)
- **Blame link** -- copy a blame URL for the visual selection to the clipboard
- **Browse** -- open the current file (or visual selection) in the browser on GitHub/GitLab

All links use the commit hash so they remain stable even as the branch moves.

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

Yanks the visual selection with file name and line numbers.

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

### Browse

Opens the current file in the browser on GitHub/GitLab. Works in both normal mode (current line) and visual mode (selected range).

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
vim.api.nvim_create_user_command("GBrowse", function()
  require("decorated_yank").browse()
end, { range = true })

-- Copy browse link to clipboard (normal + visual mode)
vim.api.nvim_create_user_command("GBrowseY", function()
  vim.fn.setreg("+", require("decorated_yank").browse_link_raw())
end, { range = true })
```

## API

| Function | Mode | Description |
|---|---|---|
| `decorated_yank()` | Visual | Yank selection with file name and line numbers |
| `decorated_yank_with_link()` | Visual | Yank selection with file name, treesitter context, and permalink |
| `blame_link()` | Visual | Copy blame URL to clipboard |
| `blame_link_raw()` | Visual | Return blame URL as a string |
| `browse()` | Normal/Visual | Open file in browser |
| `browse_link_raw()` | Normal/Visual | Return browse URL as a string |
