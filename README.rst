===============================================================================
pi314.rst.vim
===============================================================================

I like reStructuredText, but I can't get used to
`riv.vim <https://github.com/Rykka/riv.vim>`_, so I wrote one.


Usage
-------------------------------------------------------------------------------

Mappings
*******************************************************************************
* Titles (Sections)

  - ``tj`` jumps down by one rst section
  - ``tk`` jumps up by one rst section
  - ``t1`` ~ ``t6`` makes current line a rst section (add a line under current line)
  - ``t0`` generates a transition (a separate line)

* Bullet/Enumerated Lists

  - ``<leader>b`` generates a new bulleted list item
  - ``<leader>b`` again switch it between bulleted/enumberated list item
  - ``<leader>B`` removes the bullet
  - Bullets change with indent
  - ``<CR>`` automatically generates a new list item
  - When cursor is on an list item, ``o`` creates a new item under it

* Indenting

  - ``<``, ``>`` changes the indent
  - ``<TAB>``, ``<S-TAB>`` changes the indent when cursor is on logical line start

* Edit support

  - ``^``, ``I`` moves cursor to a logical line start
  - ``J`` joins two line without keeping second line's bullet

* Links

  - [visual mode] ``<leader>l`` wraps selected text into embedded URL


Options
*******************************************************************************
My rst reference: http://docutils.sourceforge.net/docs/user/rst/quickref.html


More
-------------------------------------------------------------------------------
Published under WTFPL.

This tiny project is still under developing, I am adding features I need.
Hot keys may be customizable in the future.

Although I can't get used to `riv.vim <https://github.com/Rykka/riv.vim>`_,
you should really give it a try. It's a very mature plugin.
