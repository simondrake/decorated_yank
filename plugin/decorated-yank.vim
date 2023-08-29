if exists('g:loaded_decorated_yank') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! Whid lua require'decorated_yank'.decorated_yank()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_decorated_yank = 1
