function! s:parse_line (line) " {{{
    " patterns:
    " <pspace> <bullet> <bspace> <text>
    " <pspace> <text>

    let l:ret = {}
    let l:ret['origin'] = a:line

    if a:line =~# '\v^ *[-*+] +.*$'
        " bullet -*+
        let l:matchobj = matchlist(a:line, '\v(^ *)([-*+])( +)(.*$)')
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['bullet'] = l:matchobj[2]
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
    else
        let l:matchobj = matchlist(a:line, '\v(^ *)(.*)')
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['text'] = l:matchobj[2]
    endif

    return l:ret
endfunction " }}}

function! s:get_ul_bullet (pspace) " {{{
    let l:bullet = ['*', '-', '+'][(strdisplaywidth(a:pspace) / &softtabstop) % 3]
    return l:bullet . repeat(' ', &softtabstop - strdisplaywidth(l:bullet))
endfunction " }}}

function! rst#set_bullet () " {{{
    let l:lineobj = s:parse_line(getline('.'))
    if has_key(l:lineobj, 'bullet')
        call setline('.', l:lineobj['pspace'] . s:get_ul_bullet(l:lineobj['pspace']) . l:lineobj['text'])
    endif
endfunction " }}}

function! rst#increase_indent () " {{{
    normal! >>
    let l:lineobj = s:parse_line(getline('.'))
    if has_key(l:lineobj, 'bullet')
        call rst#set_bullet()
    endif
endfunction " }}}

function! rst#decrease_indent () " {{{
    normal! <<
    let l:lineobj = s:parse_line(getline('.'))
    if has_key(l:lineobj, 'bullet')
        call rst#set_bullet()
    endif
endfunction " }}}
