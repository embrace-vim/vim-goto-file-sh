" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/> 
" Project: https://github.com/embrace-vim/vim-goto-file-sh#🚕
" Summary: Shell syntax-aware `includeexpr` for `gf`
" License: GPLv3

" -------------------------------------------------------------------

" ABOUT:
"
"   ~/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst
"
" REFER:
"
"   :h gf
"   :h includeexpr

" -------------------------------------------------------------------

" USAGE: After editing this plugin, you can reload it on the fly with
"        https://github.com/landonb/vim-source-reloader#↩️
" - Uncomment this `unlet` (or disable the `finish`) and hit <F9>.
"
" silent! unlet g:loaded_vim_goto_file_plugin_includeexpr_for_gf

if exists("g:loaded_vim_goto_file_plugin_includeexpr_for_gf") || &cp
  finish
endif

let g:loaded_vim_goto_file_plugin_includeexpr_for_gf = 1

" -------------------------------------------------------------------

" USAGE: Decide what file types you want this plugin to work on.
" - You can set this variable blank to work on all file types:
"     let g:vim_goto_file_filetypes = ''
"
" REFER: The `:help includeexpr` doc examples use `setlocal`, e.g.:
"   setlocal includeexpr=s:MyIncludeExpr()
" But if this is the only `includeexpr` you use, you can enable it
" globally without concern.
" - But if you use another `includeexpr` (e.g., you've got vim-npr
"   installed and wired to JS/TS files; or maybe you use vim-fugitive,
"   which sets includeexpr for the 'fugitive' file type), then you'll
"   want to use a filetype restriction here.

if !exists("g:vim_goto_file_filetypes")
  let g:vim_goto_file_filetypes = 'bash,sh,markdown,rst,txt'
endif

if empty(g:vim_goto_file_filetypes)
  set includeexpr=embrace#sh_expand#str_expand_shell_parameters(v:fname)
else
  exec "autocmd FileType " .. g:vim_goto_file_filetypes ..
    \ " setlocal includeexpr=embrace#sh_expand#str_expand_shell_parameters(v:fname)"
endif

