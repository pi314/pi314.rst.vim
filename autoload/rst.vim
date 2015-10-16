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

function! s:monotone (list, strict) " {{{
    let l:tmp = a:list[0]
    for s:i in a:list[1:]
        if l:tmp == s:i && a:strict
            return 0
        elseif l:tmp > s:i
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
    let l:ret['text'] = l:matchobj[2]
    return l:ret
endfunction " }}}

function! s:get_bspace (bullet) " {{{
    let bullet_len = s:vwidth(a:bullet)
    let l:bspace = repeat(' ', &softtabstop - s:vwidth(a:bullet))
    if l:bspace ==# ''
        let l:bspace = repeat(' ', &softtabstop)
    endif
    return l:bspace
endfunction " }}}

function! s:get_ul_bullet (lineobj) " {{{
    let l:pspace = a:lineobj['pspace']
    let l:bullet = ['*', '-', '+'][(s:vwidth(l:pspace) / &softtabstop) % 3]
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:get_ol_bullet (lineobj, follow) " {{{
    let l:pspace = a:lineobj['pspace']
    if has_key(a:follow, 'num')
        let l:level = (s:vwidth(l:pspace) / &softtabstop) % 3
        if l:level == 0
            let l:bullet = a:follow['num'] .'.'
        elseif l:level == 1
            let l:bullet = nr2char(a:follow['num'] + char2nr('A') - 1) .')'
        elseif l:level == 2
            let l:bullet = '('. nr2char(a:follow['num'] + char2nr('a') - 1) .')'
        endif
    else
        let l:bullet = ['1.', 'A)', '(a)'][(s:vwidth(l:pspace) / &softtabstop) % 3]
    endif
    return l:bullet . s:get_bspace(l:bullet)
endfunction " }}}

function! s:choose_bullet_type (follow, lineobj, toggle) " {{{
    if a:follow['type'] == s:UL_BULLET
        return s:UL_BULLET
    elseif a:follow['type'] == s:OL_BULLET
        return s:OL_BULLET
    elseif !has_key(a:lineobj, 'bullet-type')
        return s:UL_BULLET
    elseif has_key(a:lineobj, 'bullet-num')
        return [s:OL_BULLET, s:UL_BULLET][a:toggle]
    else
        return [s:UL_BULLET, s:OL_BULLET][a:toggle]
    endif
endfunction " }}}

function! s:look_behind_follow_bullet (lineobj) " {{{
    let l:row = a:lineobj['row']
    if l:row == 1
        return {'type': s:NO_BULLET}
    endif

    " check last line for bullet type reference
    let l:ref_line = s:parse_line(l:row - 1)
    if l:ref_line['text'] ==# '' && l:row > 2
        " last line is empty, get one more line
        let l:ref_line = s:parse_line(l:row - 2)
    endif

    if !has_key(l:ref_line, 'bullet-type')
        " reference line is not a list item
        return {'type': s:NO_BULLET}
    endif

    " reference line is a list item, but pspace is not the same
    if l:ref_line['pspace'] != a:lineobj['pspace']
        let l:ret = {}
        let l:ret['type'] = s:NO_BULLET
        let l:ret['align'] = l:ref_line['pspace']
        let l:ret['indent'] = repeat(' ', s:vwidth(l:ref_line['origin']) - s:vwidth(l:ref_line['text']))
        if has_key(l:ref_line, 'bullet-num')
            " reference line is an ordered list item
            let l:ret['num'] = l:ref_line['bullet-num'] + 1
        endif
        return l:ret
    endif

    if has_key(l:ref_line, 'bullet-num')
        " reference line is an ordered list item
        return {'type': s:OL_BULLET, 'num': l:ref_line['bullet-num'] + 1}
    endif

    " reference line is an unordered list item
    return {'type': s:UL_BULLET}
endfunction " }}}

function! rst#set_bullet (...) " {{{
    " no argument: toggle bullet
    " argument '>': adjust right
    " argument '<': adjust left
    let l:toggle = 1
    let l:adjust = 0
    if a:0 == 1
        let l:toggle = 0
        let l:adjust = 1
    endif

    let l:_ = s:parse_line('.')
    " check if we need to align to last reference line
    let l:follow = s:look_behind_follow_bullet(l:_)
    if l:adjust && has_key(l:follow, 'align')
        let l:alignable = s:monotone(
                \s:map(function('s:vwidth'),
                \[l:follow['align'], l:_['pspace'], l:follow['indent']]),
                \1)
        if a:1 ==# '<'
            if l:alignable
                let l:_['pspace'] = l:follow['align']
            else
                unlet l:follow['num']
            endif
        elseif a:1 ==# '>'
            if l:alignable
                let l:_['pspace'] = l:follow['indent']
                unlet l:follow['num']
            elseif l:_['pspace'] < l:follow['align']
                let l:_['pspace'] = l:follow['align']
            else
                unlet l:follow['num']
            endif
        endif
    endif

    if s:choose_bullet_type(l:follow, l:_, l:toggle) == s:UL_BULLET
        call setline('.', l:_['pspace'] . s:get_ul_bullet(l:_) . l:_['text'])
    else
        call setline('.', l:_['pspace'] . s:get_ol_bullet(l:_, l:follow) . l:_['text'])
    endif
endfunction " }}}

function! rst#remove_bullet () " {{{
    let l:_ = s:parse_line('.')
    call setline('.', l:_['pspace'] . l:_['text'])
endfunction " }}}

function! rst#increase_indent () " {{{
    normal! >>
    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet('>')
    endif
endfunction " }}}

function! rst#decrease_indent () " {{{
    normal! <<
    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet('<')
    endif
endfunction " }}}
