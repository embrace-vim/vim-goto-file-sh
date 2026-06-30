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
      " Strip the separator suffix from the environ name.
      " - Note the caller does not send the prefix, e.g.,
      "   don't need to sub-out: '^\${\?'
      let environ = substitute(parts[0], ':\?[-+=?]$', '', '')
      " Rebuild the alternative value.
      let alt_val = join(parts[1:], '')
      " Resolve the environ from the shell.
      let val = eval('$' .. environ)
      if empty(val)
        " Recurse.
        let recursing = 1
        let val = s:ExpandVariable(alt_val, recursing)
      endif
    endif
  endif

  return val
endfunction

" -------------------------------------------------------------------

" SAVVY: This is the |includeexpr| entry point; also a recursive callback.
function! g:embrace#sh_expand#ExpandShellParameters(fname = '') abort
  let l:fname = a:fname
  if empty(l:fname)
    let l:fname = v:fname
  endif

  let l:recursing = 0
  let l:expanded = s:ExpandVariable(l:fname, l:recursing)

  if ! s:FileReadableOrIsDirectory(l:expanded) && s:IsRelativePath(l:expanded)
    let l:res = s:RelativeToProjectRootOrParent(l:expanded)
    if ! s:FileReadableOrIsDirectory(l:res)
      let l:res = s:RelativeToUserProjectRootOrChild(l:expanded)
    endif
    if ! s:FileReadableOrIsDirectory(l:res)
      let l:res = s:FallbackBuiltinIncludeexpr(l:expanded)
    endif
    if empty(l:res)
      " This is the value Vim reports to the user, e.g.:
      "   E447: Can't find file "foo" in path
      let l:res = l:expanded
    endif
  else
    let l:res = l:expanded
  endif

  return l:res
endfunction

" -------------------------------------------------------------------

" The first time this func. is called, we need to be aware that there
" may be multiple *separate* long-form variables, e.g.:
"
"   ${XDG_DATA_HOME:-${HOME}/.local/share}/${NVIM_APPNAME:-nvim}/site/spell/en.utf-8.add
"
" - In this case, find the first matching "${", and then walk
"   character-by-character to extract a *balanced* variable.
"   - See ExtractBalancedSubstring, below.
"   - Using the example path above, the function will extract
"     and loop over two separate strings, first:
"       {XDG_DATA_HOME:-${HOME}/.local/share}
"     and second:
"       {NVIM_APPNAME:-nvim}
"
" - This func. is also called recursively, in which case we know
"   there are not separate long-form variables, and we can run a
"   simple substitute instead.
"   - The s:ExtractBalancedBraceExpanse-and-while-loop approach
"     would also work, but it's unnecessary.
"   - Note the greedy match '.{}' rather than non-greedy match '.{-}'
"     which ensures that ${...} includes submatches, e.g.,
"     '${foo:-${bar:-${baz:-bat}}}' is simply 'foo:-$' if non-greedy,
"     but when greedy, it's 'foo:-${bar:-${baz:-bat}}'.
"   - REFER: \v  starts "very magic", such that:
"            \$  literal $
"            \{  literal {
"         (.{})  match group '()', any character '.', & as many as poss. (aka '*') '{}'
"            \}  literal }
function! s:ExpandVariable(fname, recursing) abort
  if a:recursing
    " Extracts longest substring from inside outer ${}, e.g., extracts this:
    "   XDG_DATA_HOME:-${HOME}/.local/share
    " from this:
    "   ${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/spell/en.utf-8.add
    " - Bware: But doesn't work if contains 2+, i.e., ${separate} ${vars},
    "   because extracts, e.g., "separate} ${vars", not "separate".
    return substitute(
      \ a:fname,
      \ '\v\$\{(.{})\}',
      \ '\=<SID>ExpandShellParameter(submatch(1))', 'g'
      \ )
  else
    let l:resolved = a:fname
    " Returns, e.g., "{substring}"
    let l:substr = s:ExtractBalancedBraceExpanse(l:resolved)
    while l:substr != ""
      let l:innards = substitute(l:substr, '^{\(.*\)}$', '\1', '')
      let l:expanded = s:ExpandShellParameter(l:innards)
      let l:resolved = substitute(l:resolved, "$" . l:substr, l:expanded, '')
      let l:substr = s:ExtractBalancedBraceExpanse(l:resolved)
    endwhile

    return l:resolved
  endif
endfunction

" SAVVY:
"   \\v                     Very magic (changes "\" usage)
"   \(^|[^\\\\])            Start of line, or any char. except "\"
"   \\$                     Literal dolladollabill
"   \\zs                    Start of match (as opposed to
"                             using neg. look-behind \@<!)
"   \\{                     Opening (literal) brace
"   [a-zA-Z_][a-zA-Z0-9_]*  Shell variable name legal chars.
function! s:ExtractBalancedBraceExpanse(resolved) abort
  let pattern = "\\v\(^|[^\\\\])\\$\\zs\\{[a-zA-Z_][a-zA-Z0-9_]*"

  return s:ExtractBalancedSubstring(a:resolved, l:pattern, "{", "}")
endfunction

" ***

" SILLY: The LLM knew I meant "balanced"; I just wasn't thinking of the right word.
" - I added init_match to check for "$" before "{" (and not "\" before "$"). /@lb
" - THANX: https://www.google.com/search?q=vim+script+extract+substring+between+left+and+right+brackets+including+all+nested+brackets%2C+but+final+substring+should+have+equal+left+and+right+brackets
"   - GAIO: Example Usage:
"       echom ExtractBalancedSubstring("foo [a [b] c] d [e] f", "[", "]")
"       Returns: '[a [b] c]'
function! s:ExtractBalancedSubstring(str, init_match, left_char, right_char)
  let start_idx = match(a:str, a:init_match)
  if start_idx == -1
    return ""
  endif

  let balance = 0
  let end_idx = -1
  let i = start_idx

  " Loop through characters to find the boundary where left and right brackets are equal
  while i < strlen(a:str)
    let char = a:str[i]
    if char == a:left_char
      let balance += 1
    elseif char == a:right_char
      let balance -= 1
    endif

    if balance == 0
      let end_idx = i

      break
    endif

    let i += 1
  endwhile

  if end_idx != -1
    let spart = strpart(a:str, start_idx, (end_idx - start_idx + 1))
    return spart
  endif

  return ""
endfunction

" -------------------------------------------------------------------

function! s:FileReadableOrIsDirectory(fname) abort
  return !empty(a:fname) && (filereadable(a:fname) || isdirectory(a:fname))
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

" ***

function! s:RelativeToProjectRootOrParent(fname) abort
  let l:fname = ""
  " REFER: The ";" at end of finddir path searches upward.
  let l:root_dir = finddir('.git/..', expand('%:p:h').';')
  let l:abs_path = fnamemodify(l:root_dir . "/" . a:fname, ':p')
  if ! filereadable(l:abs_path) && ! isdirectory(l:abs_path)
    let l:root_dir = finddir('.git/../..', expand('%:p:h').';')
    let l:abs_path = fnamemodify(l:root_dir . "/" . a:fname, ':p')
    if filereadable(l:abs_path) || isdirectory(l:abs_path)
      let l:fname = l:abs_path
    endif
  else
    let l:fname = l:abs_path
  endif

  return l:fname
endfunction

" ***

" Test if relative to user-supplied project directory,
" or if relative to a subdir of the project directory.
" - USAGE: Set g:vim_goto_file_root in your config to your
"   main, root base dir. wherein you keep all your projects.
function! s:RelativeToUserProjectRootOrChild(fname) abort
  let l:userdir = expand(g:vim_goto_file_root)
  let l:res = fnamemodify(l:userdir . "/" . a:fname, ':p')
  if ! s:FileReadableOrIsDirectory(l:res)
    let l:matches = readdir(l:userdir, {
      \ entry -> isdirectory(fnamemodify(l:userdir . "/" . entry, ':p'))
      \   ? s:FileReadableOrIsDirectory(fnamemodify(l:userdir . "/" . entry . "/" . a:fname, ':p'))
      \   : 0})
    if len(l:matches) > 0
      let l:res = fnamemodify(l:userdir . "/" . l:matches[0] . "/" . a:fname, ':p')
    endif
  endif
  return l:res
endfunction

" ***

" REFER: Default &includeexpr is empty for lots of filetypes, set for others.
"
" There are a few ways to suss which filetypes use includeexpr:
" - The most obvious: Run `echom &includeexpr` from the file
"   you're curious about, double-checking `echom &filetype`.
"   - This approach include built-in `setlocal includeexpr=`, from
"     filetype plugins, as well as those from any user plugins.
" - To check for built-in (it's coming from inside the house)
"   wirings, excluding user config, run so-called vanilla vim, e.g.:
"     nvim --noplugin
"   - You can also run `rg includeexpr=` on vim sources, and you
"     will see all the matches (AFAIK; there are 46, in v0.12.3).
"     - This is how we sourced the code below.
"
" - SAVVY: As mentioned above, includeexpr is unset for most |filetype|s, including:
"     sh, bash, ruby, markdown, rst, text, jsonc, vim, go, javascript, css
"   - USYNC: This list and the callbacks below are all declared in the plugin:
"     g:vim_goto_file_filetypes = 'bash,css,gitcommit,go,haskell,javascript,...'
"
" - ONGNG: We'll add more filetype support below as necessary (either
"   adding to the unset list previous, or adding a callback below; and
"   adding to the plugin's default g:vim_goto_file_filetypes value).

" USYNC: You can determine which filetypes 
function! s:FallbackBuiltinIncludeexpr(fname) abort
  if &filetype == 'gitcommit'
    return s:IncludeexprGitcommit()
  elseif &filetype == 'haskell'
    return s:IncludeexprHaskell()
  elseif &filetype == 'kotlin'
    return s:IncludeexprKotlin()
  elseif &filetype == 'lua'
    return s:IncludeexprLua()
  elseif &filetype == 'perl'
    return s:IncludeexprPerl()
  elseif &filetype == 'python'
    return s:IncludeexprPython()
  elseif &filetype == 'rust'
    return s:IncludeexprRust()
  elseif &filetype == 'sass'
    return s:IncludeexprSass()
  elseif &filetype == 'scala'
    return s:IncludeexprScala()
  elseif &filetype == 'zig'
    return s:IncludeexprZig()
  endif
  return ""
endfunction

" For some filetypes, their includeexpr is a scoped callback,
" so if we wanted to support these, it'd be more work, i.e.,
" obvi., this wouldn't work:
"
"   " runtime/ftplugin/astro.vim @ 35
"   function! s:Includeexpr(fname) abort
"     " ISOFF: Cannot call s:func from a different s:.
"     return s:AstroInclude(a:fname)
"   endfunction

" COPYD: ./runtime/ftplugin/gitcommit.vim @ 17 [v0.12.3]
function! s:IncludeexprGitcommit() abort
  return substitute(v:fname,'^[bi]/','','')
endfunction

" Author doesn't use Haskell but here outta ruhspek.
" COPYD: ./runtime/ftplugin/haskell.vim @ 26 [v0.12.3] 
function! s:IncludeexprHaskell() abort
  return findfile(tr(v:fname,'.','/'),'.;')
endfunction

" COPYD: ./runtime/ftplugin/kotlin.vim @ 20 [v0.12.3]
function! s:IncludeexprKotlin() abort
  return substitute(v:fname,'\\.','/','g')
endfunction

" COPYD: ./runtime/ftplugin/lua.lua @ 4 [v0.12.3]
" - CALSO: ./runtime/ftplugin/lua.vim @ 39 [v0.12.3]
"   setlocal includeexpr=s:LuaInclude(v:fname)
"   - Aside: For Lua, default &includeexpr changes require()-style dots to slashes:
"       function s:LuaInclude(fname) abort
"         ...
"         includeexpr = "tr(v:fname,'.','/')"
"     (Though also requires that cwd be set appropriately.)
"     - SAVVY: Use |gd| to open a require() module, not |gf|.
function! s:IncludeexprLua() abort
  return v:lua.require'vim._ftplugin.lua'.includeexpr(v:fname)
endfunction

" The Luau language, aka Roblox, derived from Lua 5.1.
"
"   " COPYD: ./runtime/ftplugin/luau.vim @ 20 [v0.12.3]
"   function! s:IncludeexprLuau() abort
"     " ISOFF: Cannot call s:func from a different s:.
"     return s:LuauInclude(v:fname)
"   endfunction

" COPYD: ./runtime/ftplugin/perl.vim @ 33 [v0.12.3]
function! s:IncludeexprPerl() abort
  return substitute(substitute(substitute(substitute(v:fname,'+','',''),'::','/','g'),'->\*','',''),'$','.pm','')
endfunction

" COPYD: runtime/ftplugin/python.vim @ 33 [v0.12.3]
function! s:IncludeexprPython() abort
  return substitute(substitute(substitute(
    \v:fname,
    \b:grandparent_match,b:grandparent_sub,''),
    \b:parent_match,b:parent_sub,''),
    \b:child_match,b:child_sub,'g')
endfunction

" COPYD: ./runtime/ftplugin/rust.vim @ 59 [v0.12.3]
function! s:IncludeexprRust() abort
  return rust#IncludeExpr(v:fname)
endfunction

" COPYD: ./runtime/ftplugin/sass.vim @ 17 [v0.12.3]
function! s:IncludeexprSass() abort
  return SassIncludeExpr(v:fname)
endfunction

" COPYD: ./runtime/ftplugin/scala.vim @ 35 [v0.12.3]
function! s:IncludeexprScala() abort
  return substitute(v:fname,'\\.','/','g')
endfunction

" COPYD: ./runtime/ftplugin/zig.vim @ 40 [v0.12.3]
function! s:IncludeexprZig() abort
  return substitute(v:fname, "^([^.])$", "\1.zig", "")
endfunction

" -------------------------------------------------------------------
