############################################################
How to use ``vim-goto-file-improved`` with ``vim-async-map``
############################################################

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

``vim-goto-file-improved`` will also create a visual mode ``gf`` map, so
that you can select text and then type ``gf`` to open the selected
path.

- You can enable the visual mode ``gf`` map by adding the
  following to your Vim config:

.. code-block:: vim

  " Enable visual mode `gf` map
  let g:vim_goto_file_add_visual_mode_map = 1

