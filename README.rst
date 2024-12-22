######################################
Open ``${VAR:-/paths}`` with ``gf`` 🚕
######################################

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

Optional ``gf`` insert and visual mode maps
===========================================

.. |vim-async-map| replace:: ``vim-async-map``
.. _vim-async-map: https://github.com/embrace-vim/vim-async-map

``gf`` insert mode map
----------------------

If you'd like a nondisruptive ``gf`` binding to work from insert
mode, you can install |vim-async-map|_:

  https://github.com/embrace-vim/vim-async-map#જ⁀➴

If that plugin is installed, you can use ``gf`` from insert mode
to open file paths (and it won't interrupt your normal ``g``
keypresses — i.e., you won't see a pause after typing ``g``
like you would with a naïve ``imap gf`` binding).

- You can enable the insert mode ``gf`` map by installing
  |vim-async-map|_, and then add the following to your
  Vim config:

.. code-block:: vim

  " Enable insert mode `gf` map
  let g:vim_goto_file_add_insert_mode_map = 1

By default, the insert mode ``gf`` map will call ``gF``, so that
it honors a line number following the file path.

- If you'd like to use regular ``gf`` instead, use another
  global variable:

.. code-block:: vim

  " Use `gf` (instead of `gF`)
  let g:vim_goto_file_use_simple_gf = 1

``gf`` visual mode map
----------------------

``vim-goto-file-sh`` will also create a visual mode ``gf`` map, so
that you can select text and then type ``gf`` to open the selected
path.

- You can enable the visual mode ``gf`` map by adding the
  following to your Vim config:

.. code-block:: vim

  " Enable visual mode `gf` map
  let g:vim_goto_file_add_visual_mode_map = 1

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

.. |vim-apathy| replace:: ``https://github.com/tpope/vim-apathy``
.. _vim-apathy: https://github.com/tpope/vim-apathy

See also these similar project(s):

- *Sensible 'gf' for Node Path Relative JS module resolution per project 🐿*

  |vim-npr|_

- *Apathy sets the five path searching options — 'path', 'suffixesadd',
  'include', 'includeexpr', and 'define' — for file types I don't care
  about enough to bother with creating a proper plugin.*

  |vim-apathy|_

Installation
============

.. |help-packages| replace:: ``:h packages``
.. _help-packages: https://vimhelp.org/repeat.txt.html#packages

.. |INSTALL.md| replace:: ``INSTALL.md``
.. _INSTALL.md: INSTALL.md

Take advantage of Vim's packages feature (|help-packages|_)
and install under ``~/.vim/pack``, e.g.,:

.. code-block::

  mkdir -p ~/.vim/pack/embrace-vim/start
  cd ~/.vim/pack/embrace-vim/start
  git clone https://github.com/embrace-vim/vim-goto-file-sh.git

  " Build help tags
  vim -u NONE -c "helptags vim-goto-file-sh/doc" -c q

- Alternatively, install under ``~/.vim/pack/embrace-vim/opt`` and call
  ``:packadd vim-goto-file-sh`` to load the plugin on-demand.

For more installation tips — including how to easily keep the
plugin up-to-date — please see |INSTALL.md|_.

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

