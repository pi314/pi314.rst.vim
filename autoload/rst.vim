let s:NO_BULLET = 0
let s:OL_BULLET = 1
let s:UL_BULLET = 2

function! s:vwidth (s) " {{{
    return strdisplaywidth(a:s)
endfunction " }}}

function! s:map (func, operand) " {{{
    if type(a:func) != type(function('tr'))
        return []
    endif
    if type(a:operand) == type([])
        let l:ret = []
        for s:i in a:operand
            call add(l:ret, a:func(s:i))
        endfor
        return l:ret
    endif
    return []
endfunction " }}}

function! s:monotone (list) " {{{
    let l:tmp = a:list[0]
    for s:i in a:list[1:]
        if l:tmp >= s:i
            return 0
        endif
        let l:tmp = s:i
    endfor
    return 1
endfunction " }}}

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
    let l:ret['bullet-type'] = s:NO_BULLET
    let l:ret['text'] = l:matchobj[2]
    return l:ret
endfunction " }}}

function! s:get_bspace (bullet) " {{{
    return repeat(' ', &softtabstop - (s:vwidth(a:bullet) % &softtabstop))
endfunction " }}}

function! s:get_ul_bullet (lineobj) " {{{
    let l:pspace = a:lineobj['pspace']
    let l:bullet = ['*', '-', '+'][(s:vwidth(l:pspace) / &softtabstop) % 3]
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:get_ol_bullet (lineobj) " {{{
    let l:pspace = a:lineobj['pspace']
    let l:level = (s:vwidth(l:pspace) / &softtabstop) % 3
    if l:level == 0
        let l:bullet = a:lineobj['bullet-num'] .'.'
    elseif l:level == 1
        let l:bullet = nr2char(a:lineobj['bullet-num'] + char2nr('A') - 1) .')'
    elseif l:level == 2
        let l:bullet = '('. nr2char(a:lineobj['bullet-num'] + char2nr('a') - 1) .')'
    endif
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:look_behind_for_bullet (lineobj) " {{{
    let l:row = a:lineobj['row']
    if l:row == 1
        return
    endif

    " check last line for bullet type reference
    let l:ref_line = s:parse_line(l:row - 1)
    if l:ref_line['text'] ==# '' && l:row > 2
        " last line is empty, get one more line
        let l:ref_line = s:parse_line(l:row - 2)
    endif

    if l:ref_line['bullet-type'] == s:NO_BULLET
        " reference line is not a list item, nothing to reference
        if a:lineobj['bullet-type'] == s:OL_BULLET
            let a:lineobj['bullet-num'] = 1
        endif
        return

    elseif l:ref_line['pspace'] != a:lineobj['pspace']
        " reference line is a list item, but pspace is not the same
        let l:pspace = s:vwidth(a:lineobj['pspace'])
        let l:align = s:vwidth(l:ref_line['pspace'])
        let l:indent = s:vwidth(l:ref_line['origin']) - s:vwidth(l:ref_line['text'])
        if !s:monotone([l:align, l:pspace, l:indent])
            if a:lineobj['bullet-type'] == s:OL_BULLET
                let a:lineobj['bullet-num'] = 1
            endif
            return

        elseif a:lineobj['follow'] == '<'
            " try to align to reference line
            let a:lineobj['pspace'] = repeat(' ', l:align)
            let a:lineobj['bullet-type'] = s:OL_BULLET
            let a:lineobj['bullet-num'] = l:ref_line['bullet-num'] + 1
            return

        else
            " try to indent to reference line
            let a:lineobj['pspace'] = repeat(' ', l:indent)
            let a:lineobj['bullet-type'] = s:OL_BULLET
            let a:lineobj['bullet-num'] = 1
            return

        endif

    elseif l:ref_line['bullet-type'] == s:OL_BULLET
        " reference line is an ordered list item
        let a:lineobj['bullet-type'] = s:OL_BULLET
        let a:lineobj['bullet-num'] = l:ref_line['bullet-num'] + 1
        return
    endif

    " reference line is an unordered list item
    let a:lineobj['bullet-type'] = s:UL_BULLET
endfunction " }}}

function! s:toggle_bullet (lineobj) " {{{
    if a:lineobj['bullet-type'] == s:NO_BULLET
        let a:lineobj['bullet-type'] = s:UL_BULLET

    elseif a:lineobj['bullet-type'] == s:UL_BULLET
        let a:lineobj['bullet-type'] = s:OL_BULLET
        let a:lineobj['bullet-num'] = 1

    elseif a:lineobj['bullet-type'] == s:OL_BULLET
        let a:lineobj['bullet-type'] = s:UL_BULLET
        unlet a:lineobj['bullet-num']

    endif
endfunction " }}}

function! s:write_line (lineobj) " {{{
    let l:_ = a:lineobj
    if l:_['bullet-type'] == s:NO_BULLET
        call setline(l:_['row'], l:_['pspace'] . l:_['text'])
    elseif l:_['bullet-type'] == s:UL_BULLET
        call setline(l:_['row'], l:_['pspace'] . s:get_ul_bullet(l:_) . l:_['text'])
    else
        call setline(l:_['row'], l:_['pspace'] . s:get_ol_bullet(l:_) . l:_['text'])
    endif
endfunction " }}}

function! rst#set_bullet (...) " {{{
    let l:lineobj = s:parse_line('.')

    if a:0 == 1 && (a:1 ==# '>' || a:1 ==# '<')
        " argument '>': adjust right
        " argument '<': adjust left
        let l:lineobj['follow'] = a:1
    else
        " default: align left
        let l:lineobj['follow'] = '<'
        " just toggle the bullet, if we are wrong, next step will correct it
        call s:toggle_bullet(l:lineobj)
    endif

    " look behind to find a reference line
    call s:look_behind_for_bullet(l:lineobj)

    call s:write_line(l:lineobj)
endfunction " }}}

function! rst#remove_bullet () " {{{
    let l:lineobj = s:parse_line('.')
    unlet l:lineobj['bullet-type']
    call s:write_line(l:lineobj)
endfunction " }}}

function! rst#increase_indent () " {{{
    normal! >>
    let l:lineobj = s:parse_line('.')
    if l:lineobj['bullet-type'] != s:NO_BULLET
        call rst#set_bullet('>')
    endif
endfunction " }}}

function! rst#decrease_indent () " {{{
    normal! <<
    let l:lineobj = s:parse_line('.')
    if l:lineobj['bullet-type'] != s:NO_BULLET
        call rst#set_bullet('<')
    endif
endfunction " }}}
