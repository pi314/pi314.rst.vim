let s:OL_BULLET = 0
let s:UL_BULLET = 1

function! s:parse_line (row) " {{{
    " patterns:
    " <pspace> <bullet> <bspace> <text>
    " <pspace> <text>

    let l:ret = {}
    let l:ret['row'] = line(a:row)
    let l:line = getline(a:row)
    let l:ret['origin'] = l:line

    " bullet -*+
    let l:matchobj = matchlist(l:line, '\v(^ *)([-*+])( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['bullet-type'] = s:UL_BULLET
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
        return l:ret
    endif

    " bullet n.  a.  A.  #.
    let l:matchobj = matchlist(l:line, '\v(^ *)(\d+|[a-zA-Z]+|#)\.( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['bullet-type'] = s:OL_BULLET
        if l:matchobj[2] =~# '\v\d+'
            let l:ret['bullet-num'] = str2nr(l:matchobj[2])
        elseif l:matchobj[2] =~# '\v[a-z]+'
            let l:ret['bullet-num'] = char2nr(l:matchobj[2]) - char2nr('a') + 1
        elseif l:matchobj[2] =~# '\v[A-Z]+'
            let l:ret['bullet-num'] = char2nr(l:matchobj[2]) - char2nr('A') + 1
        elseif l:matchobj[2] ==# '#'
            let l:ret['bullet-num'] = 0
        endif
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
        return l:ret
    endif

    " bullet 1)  a)  A)  #)  (1)  (a)  (A)  (#)
    let l:matchobj = matchlist(l:line, '\v(^ *)\(?(\d+|[a-zA-Z]+|#)\)( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['bullet-type'] = s:OL_BULLET
        if l:matchobj[2] =~# '\v\d+'
            let l:ret['bullet-num'] = str2nr(l:matchobj[2])
        elseif l:matchobj[2] =~# '\v[a-z]+'
            let l:ret['bullet-num'] = char2nr(l:matchobj[2]) - char2nr('a') + 1
        elseif l:matchobj[2] =~# '\v[A-Z]+'
            let l:ret['bullet-num'] = char2nr(l:matchobj[2]) - char2nr('A') + 1
        elseif l:matchobj[2] ==# '#'
            let l:ret['bullet-num'] = 0
        endif
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
        return l:ret
    endif

    " not a bulleted list item
    let l:matchobj = matchlist(l:line, '\v(^ *)(.*)')
    let l:ret['pspace'] = l:matchobj[1]
    let l:ret['text'] = l:matchobj[2]
    return l:ret
endfunction " }}}

function! s:get_bspace (bullet) " {{{
    let bullet_len = strdisplaywidth(a:bullet)
    let l:bspace = repeat(' ', &softtabstop - strdisplaywidth(a:bullet))
    if l:bspace ==# ''
        let l:bspace = repeat(' ', &softtabstop)
    endif
    return l:bspace
endfunction " }}}

function! s:get_ul_bullet (lineobj) " {{{
    let l:pspace = a:lineobj['pspace']
    let l:bullet = ['*', '-', '+'][(strdisplaywidth(l:pspace) / &softtabstop) % 3]
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:get_ol_bullet (lineobj) " {{{
    let l:pspace = a:lineobj['pspace']
    let l:bullet = ['1.', 'A)', '(a)'][(strdisplaywidth(l:pspace) / &softtabstop) % 3]
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:choose_bullet_type (lineobj, toggle) " {{{
    if has_key(a:lineobj, 'bullet-num')
        return [s:OL_BULLET, s:UL_BULLET][a:toggle]
    else
        return [s:UL_BULLET, s:OL_BULLET][a:toggle]
    endif
endfunction " }}}

function! rst#set_bullet (...) " {{{
    let l:toggle = 1
    if (a:0 == 1) && (a:1 == 0)
        let l:toggle = 0
    endif

    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        let l:_ = l:lineobj
        if s:choose_bullet_type(l:_, l:toggle) == s:UL_BULLET
            call setline('.', l:_['pspace'] . s:get_ul_bullet(l:_) . l:_['text'])
        else
            call setline('.', l:_['pspace'] . s:get_ol_bullet(l:_) . l:_['text'])
        endif
    endif
endfunction " }}}

function! rst#increase_indent () " {{{
    normal! >>
    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet(0)
    endif
endfunction " }}}

function! rst#decrease_indent () " {{{
    normal! <<
    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet(0)
    endif
endfunction " }}}
