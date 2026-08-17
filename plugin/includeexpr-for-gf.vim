" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-goto-file-improved#🚕
" Summary: Shell syntax-aware `includeexpr` for `gf`
" License: GPLv3

" -------------------------------------------------------------------

" ABOUT:
"
"   ~/.kit/nvim/embrace-vim/start/vim-goto-file-improved/README.rst
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
" - BWARE: But you'll probably want to check if the filetype defines
"   its own includeexpr, so you can recreate it in the callback.
"   - See more helpful comments in the callback function file:
"     ./vim-goto-file-improved/autoload/embrace/sh_expand.vim
" - USAGE: To disable this plugin altogether, via config, set
"   the global var. to the magic disablement value, -1, e.g.:
"     let g:vim_goto_file_filetypes = -1

if !exists("g:vim_goto_file_filetypes")
  " ONGNG: Most filetypes don't define includeexpr, but you should check
  " before adding to this list. See comments in autoload/ file:
  "   embrace-vim/start/vim-goto-file-improved/autoload/embrace/sh_expand.vim @ 372
  " - SAVVY: The string is split in two: first for those ft's without
  "   existing includeexpr; the second for those ft's where the
  "   autoload/ callback recreates/fallbacks the built-in includeexpr.
  let g:vim_goto_file_filetypes =
    \ 'bash,conf,config,css,dosbatch,dosini,gitconfig,gitignore,go,javascript,jsonc,markdown,rst,ruby,sh,sql,text,toml,typescriptreact,vim,yaml,yaml.ansible,'
    \ . 'gitcommit,haskell,kotlin,lua,perl,python,rust,sass,scala,zig'
endif

" SAVVY: Before invoking the callback, |gf| and |gF| set v:fname to the
" string under the cursor, identifying it based on filename &iskeyword.
" - But they won't call the callback unless necessary, (e.g., for an
"   absolute path that exists, gf/gF won't call the callback).
if empty(g:vim_goto_file_filetypes)
  set includeexpr=g:embrace#sh_expand#ExpandShellParameters()
elseif g:vim_goto_file_filetypes != -1
  exec "autocmd FileType " .. g:vim_goto_file_filetypes ..
    \ " setlocal includeexpr=g:embrace#sh_expand#ExpandShellParameters()"
endif

