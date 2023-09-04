# Decorated Yank

A Plugin to decorate a yank with the filename and line numbers.

```go
-----------------------------------------------
file name:../../copy-paste-notes/internal/notes/notes.go
-----------------------------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```

A mapping (in this case `ctrl + y`) can be defined like this:

```lua
vim.api.nvim_set_keymap("v", "<C-y>", "<cmd>DecoratedYank<cr>", opts)
```

Optionally, if you have [vim-fugitive](https://github.com/tpope/vim-fugitive) or [gitlinker](https://github.com/ruifm/gitlinker.nvim) installed, you can use `DecoratedYankWithLink` to include the repository link.

```go
-----------------------------------------------
file name:../../copy-paste-notes/internal/notes/notes.go

link: https://github.com/simondrake/copy-paste-notes/blob/c8b580607a3fa2a45820f223aaaa14ed60cd54c9/internal/notes/notes.go#L15-L19
-----------------------------------------------

15 type NoteReader interface {
16 	ListNotes() ([]Note, error)
17 	GetNoteByID(int) (*Note, error)
18 	GetNoteByTitle(string) (*Note, error)
19 }
```
