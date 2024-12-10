" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-goto-file-sh#🚕
" Summary: Async insert and visual mode maps for `gf`
" License: GPLv3

" -------------------------------------------------------------------

" USAGE: Unlet var (or nix finish) & press <F9> to reload this plugin.
" USING: https://github.com/landonb/vim-source-reloader#↩️
"
" silent! unlet g:loaded_vim_goto_file_after_plugin_async_mode_maps

if exists("g:loaded_vim_goto_file_after_plugin_async_mode_maps") || &cp

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

" USAGE: Inhibit insert mode `gf` with global:
"   let g:vim_goto_file_add_insert_mode_map = 0
function! s:setup_bindings_insert_mode_gf()
  if exists("g:vim_goto_file_add_insert_mode_map")
      \ && !g:vim_goto_file_add_insert_mode_map

    return
  endif

  " The plugin alerts and hints at fixes if Python 3 not available,
  " which is required to set a timeout under 2,000 msecs.
  let g:vim_async_mapper_timeout = 100

  try
    " Wire the `gf` key sequence to the `gf` command.
    call g:embrace#amapper#register_insert_mode_map("gf", "gf")
	catch /^Vim\%((\a\+)\)\=:E117:/
    " E.g., E117: Unknown function: foo#bar#baz
    " - I.e., embrace-vim/vim-async-mapper is not installed.

    " Silently fail unless user's config explicitly wants us.
    if exists("g:vim_goto_file_add_insert_mode_map")
        \ && g:vim_goto_file_add_insert_mode_map
      echom "ALERT: Please install embrace-vim/vim-async-mapper to enable `gf` insert mode map:"
      echom "  https://github.com/embrace-vim/vim-async-mapper#જ⁀➴"
    endif
  endtry
endfunction

" Also wire visual mode `gf`.
"
" USAGE: Inhibit visual mode `gf` with global:
"   let g:vim_goto_file_add_visual_mode_map = 0
function! s:setup_bindings_visual_mode_gf()
  if exists("g:vim_goto_file_add_visual_mode_map")
      \ && !g:vim_goto_file_add_visual_mode_map

    return
  endif

  " [y]ank selected text to `"` register, then paste `"` contents as arg to :edit.
  vnoremap gf y:edit <C-r>"<CR>
endfunction

function! s:setup_bindings_all_modes_gf()
  call s:setup_bindings_insert_mode_gf()
  call s:setup_bindings_visual_mode_gf()
endfunction

" -------------------------------------------------------------------

call s:setup_bindings_all_modes_gf()

