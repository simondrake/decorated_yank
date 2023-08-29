# Decorated Yank

A Plugin to decorate a yank with the filename and line numbers. For example, given the following code in `main.go`:

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello World")
}

func anotherPrint() {
	fmt.Println("Hello Again")
}
```

By visually selecting the `anotherPrint` function and running `:DecoratedYank()` the following will be copied to the clipboard:

```
--------
main.go:
--------

9 func anotherPrint() {
10 	fmt.Println("Hello Again")
11 }
```

A mapping (in this case `ctrl + y`) can be defined like this:

```lua
vim.api.nvim_set_keymap("v", "<C-y>", "<cmd>DecoratedYank<cr>", opts)
```

