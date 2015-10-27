nnoremap <silent> <leader>b :call rst#set_bullet()<CR>
vnoremap <silent> <leader>b :call rst#set_bullet()<CR>gv
inoremap <silent> <leader>b <C-o>:call rst#set_bullet()<CR>
nnoremap <silent> <leader>B :call rst#remove_bullet()<CR>
vnoremap <silent> <leader>B :call rst#remove_bullet()<CR>gv
inoremap <silent> <leader>B <C-o>:call rst#remove_bullet()<CR>

nnoremap <silent> > :call rst#increase_indent()<CR>
nnoremap <silent> < :call rst#decrease_indent()<CR>
vnoremap <silent> > :call rst#increase_indent()<CR>gv
vnoremap <silent> < :call rst#decrease_indent()<CR>gv
