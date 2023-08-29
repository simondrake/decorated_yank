" Title:        Decorated Yank
" Description:  A plugin to decorate a yank with title and line numbers
" Last Change:  29 August 2023
" Maintainer:   Simon Drake <https://github.com/simondrake>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists('g:loaded_decorated_yank') | finish | endif " prevent loading file twice
let g:loaded_decorated_yank = 1

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" Exposes the plugin's functions for use as commands in Neovim.
command! -nargs=0 -range DecoratedYank lua require("decorated_yank").decorated_yank()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

