nnoremap <silent> <leader>b :call rst#set_bullet()<CR>
nnoremap <silent> > :call rst#increase_indent()<CR>
nnoremap <silent> < :call rst#decrease_indent()<CR>
vnoremap <silent> > :call rst#increase_indent()<CR>gv
vnoremap <silent> < :call rst#decrease_indent()<CR>gv
