<div align="center">

# Decorated Yank
##### Decorate your yanks with the filename and line numbers.

</div>

## Installation
* neovim 0.5.0+ required
* [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
* install using your favorite plugin manager

### Packer

```vim
  use {
    'simondrake/decorated_yank',
    requires = { "nvim-lua/plenary.nvim" }
  }
```

### Lazy

```vim
	{ "simondrake/decorated_yank", dependencies = { "nvim-lua/plenary.nvim" } },
```

## Set-up

If you won't be using `decorated_yank_with_link()` or `blame_link()`, you can simply call `require('decorated_yank').setup()`. If you will be using `decorated_yank_with_link()` or `blame_link()`, see the Configuration section below.

## Configuration

For `decorated_yank_with_link()` and `blame_link()`, you need to tell the plug-in the format of the links you will be using. This comes in the following parts:

* `url` - The domain itself (e.g. `github.com`). **Note:** Do not include the schema (i.e. `https`)
* `blob` - The format of the blob in the URL (e.g. for GitHub it's `/blob/`, for GitLab it's `/-/blob`)
* `blame` - The format of the blame in the URL (e.g. for GitHub it's `/blame/`, for GitLab it's `/-/blame`)
* `line_format` - The format of the line numbers (e.g. for GitHub it's `#L<start>-L<end>`, for GitLab it's `#L<start>-<end>`)

For example, if you are working on a self-hosted instance of GitLab and GitHub, you could set-up your configuration like so:

```lua
require('decorated_yank').setup({
  domains = {
    github = {
      url = "github.com",
      blob = "/blob/",
      blame = "/blame/",
      line_format = "#L%s-L%s",
    },
    yourKeyHere = {
      url = "your.custom.domain",
      blob = "/-/blob/",
      blame = "/-/blame/",
      line_format = "#L%s-%s",
    }
  }
})
```

**Note:** The object key (e.g. `yourKeyHere` above) is not important.

## Decorating

**Note:** Decorated Yank currently only works with visual selection.

### File Name and Line Numbers

```lua
:'<,'>lua require('decorated_yank').decorated_yank()
```

```go
------------------------
file name: internal/notes/notes.go
------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```

A mapping (in this case `ctrl + y`) can be defined like this:

```lua
vim.keymap.set("v", "<C-y>", function() require('decorated_yank').decorated_yank() end)
```

### File Name, Line Numbers, and Link

```lua
:'<,'>lua require('decorated_yank').decorated_yank_with_link()
```

```go
------------------------
file name: internal/notes/notes.go

type name: NoteReader

link: https://github.com/simondrake/copy-paste-notes/blob/9dc72ec691a561b543c3116a20413ec1d3b18beb/internal/notes/notes.go#L15-L19
------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```

A mapping (in this case `ctrl + y`) can be defined like this:

```lua
vim.keymap.set("v", "<C-y>", function() require('decorated_yank').decorated_yank_with_link() end)
```

## Blame Link

When using the `blame_link()` function, the plugin will place the blame link, of the visually selected lines, into the system clipboard.

```lua
:'<,'>lua require('decorated_yank').blame_link()
```

This will copy a URL such as `https://github.com/simondrake/genc/blame/2e0754b33382a965fdc1bb93097fbf68bdae20d6/main.go#L6-L6`.

A mapping (in this case ctrl + b) can be defined like this:

```lua
vim.keymap.set("v", "<C-b>", function() require('decorated_yank').blame_link() end)
```

A command (in this case `GBlame`) can be defined like this:

```lua
vim.api.nvim_create_user_command('GBlame', function(_)
  require('decorated_yank').blame_link()
end, { nargs = 0, range = true })
```
