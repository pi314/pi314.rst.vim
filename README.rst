=============
pi314.rst.vim
=============

I like reStructuredText, but I can't get used to ``riv.vim``, so I wrote one.

Usage
-----

* Titles

  - ``t0`` ~ ``t6`` makes the current line as a rst title
  - ``tj``, ``tk`` jumps between titles

* Bullet/Enumerated Lists

  - ``<leader>b`` generates a new bulleted list item
  - ``<leader>b`` again switch it between bulleted/enumberated list item
  - List item changes with indent
  - ``<CR>`` automatically generates a new list item
  - When cursor is on an list item, ``o`` creates a new item under it

* Indenting

  - ``<``, ``>`` changes the indent

My rst reference: http://docutils.sourceforge.net/docs/user/rst/quickref.html

More
----

Published under WTFPL.

This tiny project is still under developing, I am adding features I need.
Hot keys may be customizable in the future.

If you need vim rst support, try ``riv.vim``, its table-drawing feature is AMAZING.

