" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/embrace-vim/vim-goto-file-sh#🚕
" Summary: Shell syntax-aware `includeexpr` implementation for `gf`
" License: GPLv3

" -------------------------------------------------------------------

" USAGE: To work on alternative shell variable values, e.g., if you want
" `gf` on '${foo:-bar}' to resolve to 'bar' if 'foo' is not defined in
" your environment, you'll need to ensure that Vim includes colons when
" sussing filenames.
"
" - E.g., here's the author's `isfname` value:
"
"   set isfname=@,48-57,/,.,:,-,_,+,,,#,$,%,~,=,{,},(,),!,39

" -------------------------------------------------------------------

" UTEST: Here are some variable variations these functions support:
"
" - Should work on paths that `gf` supports by default, e.g.:
"
"     ~/.config/nvim/init.lua
"
"     $HOME/.config/nvim/init.lua
"
"     ${HOME}/.config/nvim/init.lua
"
"     "${HOME}/.config/nvim/init.lua"
"
" - Should use the alternative variable value when an environment variable
"   is undefined, e.g.:
"
"     ${XDG_CONFIG:-${HOME}/.config}/nvim/init.lua
"
" - Should resolve nested variable values, e.g.:
"
"     " Note `gf` won't work from this file unless 'vim' filetype
"     " is registered in g:vim_goto_file_filetypes
"     ${NVIM_CONFIG:-${XDG_CONFIG:-${HOME}/.config}/nvim}/init.lua
"
" - Should work when multiple variables are on the same line, e.g.:
"
"     ${HOME}/.inputrc ${HOME}/.vimrc
"
" SAVVY: Note that how `gf` handles quoted paths relies on the `isfname` value.
"
" - E.g., you might support single-quotes in path names, e.g.:
"
"     set isfname=@,48-57,/,.,:,-,_,+,,,#,$,%,~,=,{,},(,),!,39
"
"  (Note that ASCII code 39 is the single quote, which we use instead
"  of a delimited quote character, e.g., \', otherwise you'll have issues
"  with plugins that try to cache the isfname.)
"
" - If isfname includes a single quote, than `gf` won't work if the path
"   is single-quoted, e.g., this won't work:
"
"     '${HOME}/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst'
"
"   - But `gf` will work if a pathname has an actual single quote in
"     it, e.g.:
"
"     ${HOME}/User'sPhotos
"
" - Also, in general, the isfname setting won't include spaces.
"
"  - E.g., this path is *not* supported by `gf`:
"
"      ${HOME}/User's Photos
"
"     though if you've made it this far as a developer, you probably have
"     a distaste for spaces in filenames, anyway (and thank you very much,
"     Apple, for such paths as ~/Library/Application\ Support/ !! =).
"
"   - Note you could add a space to isfname (where 32 is ASCII space value),
"     e.g.:
"
"       set isfname=@,48-57,/,.,:,-,_,+,,,#,$,%,~,=,{,},(,),!,39,32
"
"     But then `gf` won't work if the pathname is preceded or followed
"     by other text (unless it's double-quoted, or otherwise delimited
"     from surrounding text). And you'd likely break other Vim
"     functionality anyway. So we're done talking about it.

" -------------------------------------------------------------------

" CXREF: These functions are called by this project's plugin:
" ~/.vim/pack/embrace-vim/start/vim-goto-file-sh/plugin/includeexpr-for-gf.vim

function! s:ExpandShellParameter(var) abort
  try
    let val = eval('$' .. a:var)
  catch
    let val = ''
  endtry

  if empty(val)
    " Split on any of the shell Parameter Expansion tokens (:- := :? :+ - +)
    " - REFER: See `man dash`. Also, from `man bash`: "Omitting the colon
    "   results in a test only for a parameter that is unset." So the regex
    "   matches with or with the colon, and one of: - + = ?
    " Also keep separator(s) (\zs), because split() does not have a max-count arg.
    " - We only want to split once, so we can recurse into the second part,
    "   in case the first part — the environment variable name — is undefined.
    "   E.g., if a:var is set to the following, we want the first part, 'foo':
    "     ${foo:-${bar:-/baz}/qux-quux}
    "   and we'll pass along 'bar:-/baz}/qux-quux' if 'foo' is undefined.
    let keepempty = 0
    let parts = split(a:var, ':\?[-+=?]\zs', keepempty)

    if len(parts) >= 2
      " Strip the separator from the environ name.
      let environ = substitute(parts[0], ':\?[-+=?]$', '', '')
      " Rebuild the alternative value.
      let alt_val = join(parts[1:], '')
      " Resolve the environ from the shell.
      let val = eval('$' .. environ)
      if empty(val)
        " Recurse.
        let val = g:embrace#sh_expand#ExpandShellParameters(alt_val)
      endif
    endif
  endif

  return val
endfunction

function! g:embrace#sh_expand#ExpandShellParameters(fname = '') abort
  let l:fname = a:fname
  if ! l:fname
    let l:fname = v:fname
  endif

  let l:res = s:ExpandVariable(l:fname)

  if ! filereadable(l:res) && IsRelativePath(l:res)
    " REFER: The ";" at end of finddir path searches upward.
    let l:root_dir = finddir('.git/..', expand('%:p:h').';')
    let l:abs_path = fnamemodify(l:root_dir . "/" . l:res, ':p')
    if ! filereadable(l:abs_path) && ! isdirectory(l:abs_path)
      let l:root_dir = finddir('.git/../..', expand('%:p:h').';')
      let l:abs_path = fnamemodify(l:root_dir . "/" . l:res, ':p')
      if filereadable(l:abs_path) || isdirectory(l:abs_path)
        let l:res = l:abs_path
      endif
    else
      let l:res = l:abs_path
    endif
  endif

  return l:res
endfunction

" Use greedy match '.{}' rather than non-greedy match '.{-}' so that ${...}
" includes submatches, e.g., '${foo:-${bar:-${baz:-bat}}}' is simply 'foo:-$'
" if non-greedy, but when greedy, it's 'foo:-${bar:-${baz:-bat}}'.
function! s:ExpandVariable(fname) abort
  return substitute(
    \ a:fname,
    \ '\v\$\{(.{})\}',
    \ '\=<SID>ExpandShellParameter(submatch(1))', 'g'
    \ )
endfunction

" THANX: https://www.google.com/search?q=vimscript+check+if+string+is+relative+path
function! s:IsRelativePath(path) abort
  if has('win32') || has('win64')
    " Windows absolute paths start with a drive letter (C:\) or a UNC network share (\\)
    return a:path !~? '^[a-z]:[/\\]' && a:path !~ '^\\\\[^\\]'
  else
    " Unix/Linux/macOS absolute paths always start with /
    return a:path !~ '^/' && a:path !~ '^\~'
  endif
endfunction

