" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-goto-file-sh#🚕
" Summary: Async insert and visual mode maps for `gf`
" License: GPLv3

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_vim_goto_file_after_plugin_async_mode_maps
endif

if exists('g:loaded_vim_goto_file_after_plugin_async_mode_maps') || &cp

  finish
endif

let g:loaded_vim_goto_file_after_plugin_async_mode_maps = 1

" -------------------------------------------------------------------

" Add async 2-character insert mode map so you can run `gf` from insert
" mode (and use async plugin so it doesn't cause input to briefly pause,
" which is how a naïve `imap gf gf` would behave).
"
" - Note after typing `gf` in insert mode, what you typed will be
"   undone, so it won't mark your buffer edited (unless you were
"   typing something within the timeout, in which case the async
"   plugin will <Backspace> to remove the sequence, and your buffer
"   will be marked edited).
"
" SAVVY: In English, there are at least 19 hits for `.*gf.*`: clingfish,
" dogface, dogfight, dogfish, eggfruit, frogfish, hagfish, hogfish, kingfish,
" kingfisher, lungfish, meaningful, pigfish, Siegfried, slugfest, songfest,
" songful, stagflation, wrongful. | https://www.visca.com/regexdict/
" - So `gf` is not very common to type, and therefore an insert mode `gf`
"   *shouldn't* be that disruptful, but might instead be *meaningful*, ha.
"   Unless you 'slugfest' a lot, or like to talk about 'kingfishers', perhaps.

" This works, but the interaction is not elegant, because Vim pauses
" briefly after you type 'g':
"
"   inoremap gf <C-O>gf
"
" So we'll use a fancy plugin that beautifies insert mode map UX.
"
" - We use a fork of vim-easyescape, which maps all permutations of
"   whatever sequence you want to just the <Escape> command. (It's most
"   common use if to map `jk` and `kj` so you can easily exit from insert
"   mode with your right hand.) But vim-easyescape doesn't support other
"   commands. It also wires all permutations of the key sequence (and,
"   e.g., we don't want to also map `fg`). Also, it leaves the buffer
"   edited after removing the key sequence (because it uses <Backspace>
"   instead of :undo to remove it). In any case, that was some of the
"   motivation for the fork.

" USAGE: Enable (opt-in) insert mode `gf` with global:
"   let g:vim_goto_file_add_insert_mode_map = 1
function! s:CreateMaps_InsertMode_gf() abort
  if !s:is_flag_enabled("g:vim_goto_file_add_insert_mode_map")

    return
  endif

  try
    " Wire the `gf` key sequence to the `gF` (or `gf`) command.
    call g:embrace#async_map#RegisterInsertModeMap("gf", s:gf_command)
  catch /^Vim\%((\a\+)\)\=:E117:/
    " E.g., E117: Unknown function: foo#bar#baz
    echom "ALERT: Please install embrace-vim/vim-async-map to enable `gf` insert mode map:"
    echom "  https://github.com/embrace-vim/vim-async-map#જ⁀➴"
  endtry
endfunction

" ***

" Also wire visual mode `gf`.
"
" USAGE: Enable (opt-in) visual mode `gf` with global:
"   let g:vim_goto_file_add_visual_mode_map = 1
function! s:CreateMaps_VisualMode_gf() abort
  if !s:is_flag_enabled("g:vim_goto_file_add_visual_mode_map")

    return
  endif

  " [y]ank selected text to `"` register, then paste `"` contents as arg to :edit.
  vnoremap gf y:edit <C-r>"<CR>
endfunction

" -------------------------------------------------------------------

function! s:is_flag_enabled(var_name) abort
  if !exists(a:var_name) || !eval(a:var_name)

    return 0
  endif

  return 1
endfunction

" ***

" Set a reasonable async mapper timeout.
function! s:InitAsyncMapTimeout() abort
  if exists("g:vim_async_map_timeout")

    return
  endif

  " The plugin alerts and hints at fixes if Python 3 not available,
  " which is required to set a timeout under 2,000 msecs.
  let g:vim_async_map_timeout = 100
endfunction

" ***

" Use `gF` command, or `gf` is user wants that instead.
function! s:ChooseCommand_gf() abort
  let s:gf_command = "gF"

  if exists("g:vim_goto_file_use_simple_gf")
      \ && g:vim_goto_file_use_simple_gf == 1

    let s:gf_command = "gf"
  endif
endfunction

" ***

function! s:CreateMaps_gf() abort
  if !s:is_flag_enabled("g:vim_goto_file_add_insert_mode_map")
    \ && !s:is_flag_enabled("g:vim_goto_file_add_visual_mode_map")

    return
  endif

  call s:InitAsyncMapTimeout()
  call s:ChooseCommand_gf()
  call s:CreateMaps_InsertMode_gf()
  call s:CreateMaps_VisualMode_gf()
endfunction

" -------------------------------------------------------------------

call s:CreateMaps_gf()

