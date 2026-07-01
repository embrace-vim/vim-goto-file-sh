@@@@@@@@@@@@@@@@@@@@@@@@@
vim-goto-file-improved 🛴
@@@@@@@@@@@@@@@@@@@@@@@@@

#######################################################################
``gf`` that expands ``${VAR:-default}/`` and opens ``./relative`` paths
#######################################################################

About This Plugin
=================

This plugin adds *multiple* improvements to the Neovim
(or Vim) |gf-cmd|_ and |cmd-gF|_ commands, so you can:

- 1.) Use *alternative* (aka default) variable values.

- 2.) Use path strings *relative* to a file's *project root*, or its parent.

- 3.) Use path strings *relative* to an arbitrary *user-designated* directory,
  or a child thereof.

Deeper Details
==============

The enhanced ``gf``/``gF`` lets you:

- 1.) Use an *alternative* (aka |param-default|_) variable value.

  - E.g., the following path resolves to ``$HOME/Documents/some/file``::

      ${MY_BESPOKE_VARIABLE:-${HOME}/Documents}/some/file

- 2.) Use path string *relative* to project root, or its parent.

  - E.g., with this file open in Neovim, you can ``gf`` the following path::

      ./vim-goto-file-sh/autoload/embrace/sh_expand.vim

  - And you can also use so-called "aunt or uncle" paths [*my term,
    sorry*], relative to the project's parent directory.

    - E.g., you can also ``gf`` the following path::

        ./vim-blinky-search//README.rst

      provided that ``vim-blinky-search/`` exists alongside
      ``vim-goto-file-sh/``.

- 3.) Use path string relative to arbitrary *user-designated*
  directory, or a child thereof.

  - E.g., if you stashed all your projects under a directory
    named ``~/.kit``, then you could ``gF`` the following path::

      neovim/src/nvim/file_search.c @ 1759

    provided that you added the following to your Neovim config::

      vim.g.vim_goto_file_root = "~/.kit"

    And that *either* the top-level path exists, e.g.::

      ~/.kit/neovim/

    Or it can be found in any child directory (i.e., a single
    level down), e.g.::

      ~/.kit/nvim/neovim/

    would be acceptable.

  - Note this plugin also supports Vim. You'd only need to
    set the global variable slightly differently, e.g.,::

      let g:vim_goto_file_root = "~/.kit"

Default Behavior
================

- The ``gf`` and ``gF`` commands are used to open the
  path represented by the word under the cursor (using
  ``isfname`` to match the word characters; see
  `below <#configure-isfname>`__).

  - |gf-cmd|_ will *edit the filename at
    (or after) cursor. / Mnemonic: "goto file".*

- But the default behavior generally only works on *full* paths,
  and it has limited ability to expand shell variables.

  - For instance, the built-in function would work on this path::

    ${HOME}/.local/share/nvim/site/spell/en.utf-8.add

  - But it would not work on this path::

    ${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/spell/en.utf-8.add

  - Specifically, the built-in ``gf`` command will resolve tilde
    (``~``) and it will work on short-form environment variables.
    But it does not work on long-form variables with default values.

- For reference, here's a sampling of paths that built-in ``gf`` handles::

    ~/.local/share/nvim/lazy/lazy.nvim/README.md

    $HOME/.local/share/nvim/lazy/lazy.nvim/README.md

    ${HOME}/.local/share/nvim/lazy/lazy.nvim/README.md

    /home/$LOGNAME/.gitignore

- And here's a sampling of some paths on which built-in ``gf`` won't work::

    ${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/spell/en.utf-8.add

    ${NVIM_APPNAME_FULL:-${XDG_DATA_HOME:-${HOME}/.local/share}/nvim}/site/spell/en.utf-8.add

     ~/.local/share/${NVIM_APPNAME:-nvim}/site/spell/en.utf-8.add

Fortunately, Neovim provides the |includeexpr|_ hook for when
|gf-cmd|_ comes up empty — so we don't need to rewrite the
``gf`` function, we can just add an ``includeexpr`` function.

Fallback Behavior
-----------------

- Note that *some* |filetype|_'s set a custom |includeexpr|_.

  - This is often so you can use |gf-cmd|_ on import package names.

  - This plugin will fallback to the default behavior if the
    path is not otherwise identified (so this plugin should
    not change any of the default behavior to which you may
    already by accustomed).

.. Refer: v0.13.0-dev
.. |gf-cmd| replace:: ``gf``
.. _gf-cmd: https://neovim.io/doc/user/editing/#gf

.. |cmd-gF| replace:: ``gF``
.. _cmd-gF: https://neovim.io/doc/user/editing/#gF

.. |param-default| replace:: default
.. _param-default: https://tldp.org/LDP/abs/html/parameter-substitution.html

.. |includeexpr| replace:: ``includeexpr``
.. _includeexpr: https://neovim.io/doc/user/options/#'includeexpr'

.. |filetype| replace:: ``filetype``
.. _filetype: https://neovim.io/doc/user/options/#'includeexpr'

.. |isfname| replace:: ``isfname``
.. _isfname: https://neovim.io/doc/user/options/#'isfname'

Install the Plugin
==================

Install this plugin like you would any Neovim or Vim plugin —
probably using |lazy.nvim|_ or |vim-plug|_.

.. |lazy.nvim| replace:: ``lazy.nvim``
.. _lazy.nvim: https://github.com/folke/lazy.nvim

.. |vim-plug| replace:: ``vim-plug``
.. _vim-plug: https://github.com/junegunn/vim-plug

Configure the Plugin
====================

E.g., here's how you might install and configure the plugin
from Lua using |lazy.nvim|_::

  {
    "embrace-vim/vim-goto-file-sh",

    event = "VeryLazy",

    init = function()
      -- Set to empty string to enable for all filetypes:
      --
      --  vim.g.vim_goto_file_filetypes = ""
    end,

    config = function()
      -- Fallback path for relative paths:
      -- - If not relative to the project root or its parent,
      --   tests if relative to this path or any sudirectory.
      --
      --  vim.g.vim_goto_file_root = "~/"
    end,
  },

By default, this plugin will only change ``includeexpr`` for specific
file types (and it will not alert you if it clobbers an existing
``includeexpr``).

- Currently, this plugin is activated on these file types, none of
  which define a custom ``includeexpr`` otherwise::

    bash, conf, config, css, dosbatch, dosini, gitconfig,
    gitignore, go, javascript, jsonc, markdown, rst, ruby,
    sh, sql, text, toml, typescriptreact, vim, yaml, yaml.ansible

- And this plugin is also activated on these file types, each of which
  has a custom, built-in ``includeexpr`` behavior that is used as a
  fallback if the path is not identified using variable expansion
  and isn't a relative path::

    gitcommit, haskell, kotlin, lua, perl, python, rust, sass, scala, zig

- Specifically, this plugin works on: Bash and Shell file types;
  as well as reST, Markdown, and Text; also Config files, CSS,
  DOS Batch and INI, Git ignore, Go, JavaScript, JSON (not that
  JSON supports comments), Ruby, SQL, TOML, TypeScript, Vim, Yaml
  (including Ansible Yaml), Git-commit, Haskell, Kotlin, Lua, Perl,
  Python, Rust, Sass, Scala, and Zig.

- This plugin will technically work on any ``filetype``, but we
  add each one deliberately, so we can verify if we need to
  emulate any custom, built-in ``includeexpr`` behavior.

- You can also use a global variable to add or remove file types.

  Here's the default value::

    vim.g.vim_goto_file_filetypes = ""
      .. "bash,conf,config,css,dosbatch,dosini,gitconfig,gitignore,go,"
      .. "javascript,jsonc,markdown,rst,ruby,sh,sql,text,toml,"
      .. "typescriptreact,vim,yaml,yaml.ansible,"
      .. "gitcommit,haskell,kotlin,lua,perl,python,rust,sass,scala,zig"

- If you'd like to use this plugin for *all* file types (by setting
  a global ``includeexpr``, and not one for each file type), set the
  config variable to the empty string, e.g.::

    vim.g.vim_goto_file_filetypes = ""

- To disable the plugin (besides uninstalling it), you
  can set the file-types config variable to ``-1``::

    vim.g.vim_goto_file_filetypes = -1

Configure ``isfname``
=====================

To ensure variable expansion works, you'll want to ensure that
|isfname|_ is configured properly.

- To work on long-form variables with alternative shell values, e.g.,
  if you want ``gf`` to be able to resolve ``${foo:-bar}``, then
  you need to ensure that the editor includes colons when sussing
  filenames.

  - E.g., here's the author's ``isfname`` value (where 39 is the
    single quote character, 48-57 are the characters '0'-'9',
    and "@-@" is the literal at sign "@" (because the leading
    "@" matches all ``isalpha()`` characters)):

.. code-block::

  set isfname=@,48-57,/,.,:,-,_,+,,,#,$,%,~,=,{,},(,),!,39,@-@

Caveats
=======

This plugin calls ``eval('$<var>')`` on the environment variables
to try to resolves matches. So it matters how you started Neovim.

- If you've started Neovim (``nvim``) from a shell terminal,
  it'll resolve environments normally defined in your shell.

- But if you've started Neovim some other way, e.g., if you
  started Neovide via Spotlight Search, or using GNOME Shell
  Activities, then your Neovim environment won't include the
  same environment variables that your shell normally has.

Reference
=========

See Neovim online help for details about |gf-cmd|_,
|cmd-gF|_, |includeexpr|_, and |isfname|_::

  :h gf

  :h gF

  :h includeexpr

  :h isfname

Related projects
================

.. |vim-npr| replace:: ``https://github.com/tomarrell/vim-npr#🐿``
.. _vim-npr: https://github.com/tomarrell/vim-npr

.. |vim-apathy| replace:: ``https://github.com/tpope/vim-apathy``
.. _vim-apathy: https://github.com/tpope/vim-apathy

See also these similar projects:

- *Sensible 'gf' for Node Path Relative JS module resolution per project 🐿*

  |vim-npr|_

- *Apathy sets the five path searching options — 'path', 'suffixesadd',
  'include', 'includeexpr', and 'define' — for file types I don't care
  about enough to bother with creating a proper plugin.*

  |vim-apathy|_

Attribution
===========

.. |embrace-vim| replace:: ``embrace-vim``
.. _embrace-vim: https://github.com/embrace-vim

.. |@landonb| replace:: ``@landonb``
.. _@landonb: https://github.com/landonb

The |embrace-vim|_ logo by |@landonb|_ contains
`coffee cup with straw by farra nugraha from Noun Project
<https://thenounproject.com/icon/coffee-cup-with-straw-6961731/>`__
(CC BY 3.0).

