####################
``vim-goto-file-sh``
####################

About This Plugin
=================

This plugin enables the Vim ``gf`` command to resolve shell variable
paths, including those with alternative values.

For example, you could position the cursor over the following path
and press ``gf``:

.. code-block::

  ${VIM_PACK:-${HOME}/.vim/pack}/embrace-vim/start/vim-goto-file-sh/README.rst

and Vim would open the file at
``~/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst``.

Further Details
===============

The Vim ``gf`` command ("Edit the file whose name is under or after the cursor")
will resolve tilde and the HOME environ variable, but not other variables.

- E.g., ``gf`` works on these paths:

.. code-block::

    ~/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst
    
    "$HOME/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst"

    "${HOME}/.vim/pack/embrace-vim/start/vim-goto-file-sh/README.rst"

- But Vim's built-in ``gf`` won't work on these paths:

.. code-block::

    "${VIM_PACK:-${HOME}/.vim/pack}/embrace-vim/start/vim-goto-file-sh/README.rst"

    "${EMBRACE_VIM:-${VIM_PACK:-${HOME}/.vim/pack}/embrace-vim/start}/vim-goto-file-sh/README.rst"

Fortunately, Vim provides the ``includeexpr`` hook for when ``gf`` comes
up empty — so we don't need to rewrite the ``gf`` function, we can just
add an ``includeexpr`` function.

Setup
=====

First, install this plugin (see `Installation`_, below).

Next, ensure that ``isfname`` is configured properly.

- To work on alternative shell variable values, e.g., if you want
  ``gf`` to resolve ``${foo:-bar}`` to ``bar`` if ``$foo`` is not defined
  in the environment, then you'll need to ensure that Vim includes colons
  when sussing filenames.

  - E.g., here's the author's ``isfname`` value (where 39 is the
    single quote character, and 48-57 are the characters '0'-'9'):

.. code-block::

  set isfname=@,48-57,/,.,:,-,_,+,,,#,$,%,~,=,{,},(,),!,39

Configuration
=============

By default, this plugin will only change ``includeexpr`` for specific
file types (and it will not alert you if it clobbers an existing
``includeexpr``).

- Specifically, this plugin works on Bash and Shell file types,
  as well as reST, Markdown, and Text.

- You can use a global variable to add or remove file types.

  Here's the default value:

.. code-block::

  let g:vim_goto_file_filetypes = 'bash,sh,markdown,rst,txt'

- If you'd like a global ``includeexpr`` (e.g., ``set includeexpr = ...``
  and not ``set local includeexpr = ...``), you can set this value to
  the empty string, e.g.:

.. code-block::

  let g:vim_goto_file_filetypes = ''

Caveats
=======

This plugin calls ``eval('$<var>')`` on the environment variables
to try to resolves matches. So it matters how you started Vim.

- If you've started Vim/gVim from a shell terminal, it'll resolve
  environments normally defined in your shell.

- But if you've started Vim/gVim some other way, e.g., if you started
  MacVim via Spotlight Search, then your Vim environment won't include
  the same environment variables that your shell normally has.

  - Just FYI, you might want to start Vim/gVim from your shell to
    get this most utility out of this plugin.

Reference
=========

See Vim online help for details about ``gf`` and ``includeexpr``:

.. code-block:: vim

  :h gf

  :h includeexpr

Related projects
================

.. |vim-npr| replace:: ``https://github.com/tomarrell/vim-npr#🐿``
.. _vim-npr: https://github.com/tomarrell/vim-npr

See also these similar project(s):

- *Sensible 'gf' for Node Path Relative JS module resolution per project 🐿*

  |vim-npr|_

Installation
============

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block::

    mkdir -p ~/.vim/pack/embrace-vim/start
    cd ~/.vim/pack/embrace-vim/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block::

    mkdir -p ~/.vim/pack/embrace-vim/opt
    cd ~/.vim/pack/embrace-vim/opt

Clone the project to the desired path:

.. code-block::

    git clone https://github.com/embrace-vim/vim-goto-file-sh.git

If you installed to the optional path, tell Vim to load the package:

.. code-block:: vim

    :packadd! vim-goto-file-sh

Just once, tell Vim to build the online help:

.. code-block:: vim

    :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

    :help vim_goto_file_sh

.. |vim-plug| replace:: ``vim-plug``
.. _vim-plug: https://github.com/junegunn/vim-plug

.. |Vundle| replace:: ``Vundle``
.. _Vundle: https://github.com/VundleVim/Vundle.vim

.. |myrepos| replace:: ``myrepos``
.. _myrepos: https://myrepos.branchable.com/

.. |ohmyrepos| replace:: ``ohmyrepos``
.. _ohmyrepos: https://github.com/landonb/ohmyrepos

Note that you'll need to update the repo manually (e.g., ``git pull``
occasionally).

- If you'd like to be able to update from within Vim, you could use
  |vim-plug|_.

  - You could then skip the steps above and register
    the plugin like this, e.g.:

.. code-block:: vim

    call plug#begin()

    " List your plugins here
    Plug 'embrace-vim/vim-goto-file-sh'

    call plug#end()

- And to update, call:

.. code-block:: vim

    :PlugUpdate

- Similarly, there's also |Vundle|_.

  - You'd configure it something like this:

.. code-block:: vim

    set nocompatible              " be iMproved, required
    filetype off                  " required

    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')

    " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'

    Plugin 'embrace-vim/vim-goto-file-sh'

    " All of your Plugins must be added before the following line
    call vundle#end()            " required
    filetype plugin indent on    " required
    " To ignore plugin indent changes, instead use:
    "filetype plugin on

- And then to update, call one of these:

.. code-block:: vim

    :PluginInstall!
    :PluginUpdate

- Or, if you're like the author, you could use a multi-repo Git tool,
  such as |myrepos|_ (along with the author's library, |ohmyrepos|_).

  - With |myrepos|_, you could update all your Git repos with
    the following command:

.. code-block::

    mr -d / pull

- Alternatively, if you use |ohmyrepos|_, you could pull
  just Vim plugin changes with something like this:

.. code-block::

    MR_INCLUDE=vim-plugins mr -d / pull

- After you identify your vim-plugins using the 'skip' action, e.g.:

.. code-block::

    # Put this in ~/.mrconfig, or something loaded by it.
    [DEFAULT]
    skip = mr_exclusive "vim-plugins"

    [pack/embrace-vim/start/vim-goto-file-sh]
    lib = remote_set origin https://github.com/embrace-vim/vim-goto-file-sh.git

    [DEFAULT]
    skip = false

Attribution
===========

.. |embrace-vim| replace:: ``embrace-vim``
.. _embrace-vim: https://github.com/embrace-vim

.. |@landonb| replace:: ``@landonb``
.. _@landonb: https://github.com/landonb

The |embrace-vim|_ logo by |@landonb|_ contains
`embrace by Olena Panasovska from Noun Project
<https://thenounproject.com/icon/embrace-3819610/>`__
(CC BY 3.0).

