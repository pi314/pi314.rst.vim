nnoremap <buffer> <silent> <leader>b :call rst#set_bullet()<CR>
vnoremap <buffer> <silent> <leader>b :call rst#set_bullet()<CR>gv
inoremap <buffer> <silent> <leader>b <C-o>:call rst#set_bullet()<CR>
nnoremap <buffer> <silent> <leader>B :call rst#remove_bullet()<CR>
vnoremap <buffer> <silent> <leader>B :call rst#remove_bullet()<CR>gv
inoremap <buffer> <silent> <leader>B <C-o>:call rst#remove_bullet()<CR>

nnoremap <buffer> <silent> > :call rst#increase_indent()<CR>
nnoremap <buffer> <silent> < :call rst#decrease_indent()<CR>
vnoremap <buffer> <silent> > :call rst#increase_indent()<CR>gv
vnoremap <buffer> <silent> < :call rst#decrease_indent()<CR>gv

inoremap <buffer> <silent> <CR> <C-r>=rst#carriage_return()<CR>
nnoremap <buffer> <silent> o A<C-r>=rst#carriage_return()<CR>

nnoremap <buffer> <silent> ^ :call rst#move_cursor_to_line_start()<CR>
vnoremap <buffer> <silent> ^ :call rst#move_cursor_to_line_start('v')<CR>
nnoremap <buffer> <silent> I I<C-o>:call rst#move_cursor_to_line_start()<CR>

nnoremap <buffer> <silent> t0 o<ESC>0D8i-<ESC>0

for s:level in range(1, 6)
    execute "nnoremap <buffer> <silent> t". s:level ." :call rst#make_title(". s:level .")<CR>"
endfor
