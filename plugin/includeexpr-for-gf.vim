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

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_vim_goto_file_plugin_includeexpr_for_gf
endif

if exists('g:loaded_vim_goto_file_plugin_includeexpr_for_gf') || &cp

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
  set includeexpr=g:embrace#sh_expand#ExpandShellParameters(v:fname)
else
  exec "autocmd FileType " .. g:vim_goto_file_filetypes ..
    \ " setlocal includeexpr=g:embrace#sh_expand#ExpandShellParameters(v:fname)"
endif

