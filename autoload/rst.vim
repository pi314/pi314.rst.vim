let s:NO_BULLET = 0
let s:OL_BULLET = 1
let s:UL_BULLET = 2

let s:cursor_row = -1
let s:cursor_col = -1
function! s:save_cursor_position () " {{{
    let s:cursor_row = line('.')
    let s:cursor_col = col('.')
endfunction " }}}
function! s:restore_cursor_position (...) " {{{
    if a:0 == 0
        call cursor(s:cursor_row, s:cursor_col)
    elseif a:0 == 2
        call cursor(s:cursor_row + a:1, s:cursor_col + a:2)
    endif
endfunction " }}}

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

    if get(l:ref_line, 'bullet-type', s:NO_BULLET) == s:NO_BULLET
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
        let l:myindent = s:vwidth(a:lineobj['origin']) - s:vwidth(a:lineobj['text'])

        if !s:monotone([l:align, l:pspace, l:indent])
            " current line is out of align/indent range
            if s:monotone([l:pspace, l:align, l:myindent])
                if a:lineobj['follow'] == '>'
                    let a:lineobj['pspace'] = repeat(' ', l:align)
                    let a:lineobj['bullet-num'] = l:ref_line['bullet-num'] + 1
                elseif a:lineobj['follow'] == '<'
                    let a:lineobj['pspace'] = repeat(' ', l:pspace - (l:myindent - l:align))
                    let a:lineobj['bullet-num'] = 1
                endif
            elseif a:lineobj['bullet-type'] == s:OL_BULLET
                let a:lineobj['bullet-num'] = 1
            endif
            return

        elseif a:lineobj['follow'] == '<'
            " try to align to reference line
            let a:lineobj['pspace'] = repeat(' ', l:align)
            let a:lineobj['bullet-type'] = l:ref_line['bullet-type']
            if l:ref_line['bullet-type'] == s:OL_BULLET
                let a:lineobj['bullet-num'] = l:ref_line['bullet-num'] + 1
            endif
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
    if get(a:lineobj, 'bullet-type', s:NO_BULLET) == s:NO_BULLET
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
    call s:save_cursor_position()
    if get(l:_, 'bullet-type', s:NO_BULLET) == s:NO_BULLET
        call setline(l:_['row'], l:_['pspace'] . l:_['text'])
    elseif l:_['bullet-type'] == s:UL_BULLET
        call setline(l:_['row'], l:_['pspace'] . s:get_ul_bullet(l:_) . l:_['text'])
    else
        call setline(l:_['row'], l:_['pspace'] . s:get_ol_bullet(l:_) . l:_['text'])
    endif
    if l:_['row'] == line('.')
        let l:origin_len = s:vwidth(l:_['origin'])
        let l:new_len = s:vwidth(getline('.'))
        call s:restore_cursor_position(0, l:new_len - l:origin_len)
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
    if has_key(l:lineobj, 'bullet-type')
        unlet l:lineobj['bullet-type']
        call s:write_line(l:lineobj)
    endif
endfunction " }}}

function! rst#increase_indent () " {{{
    call s:save_cursor_position()
    normal! >>
    call s:restore_cursor_position(0, &shiftwidth)

    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet('>')
    endif
endfunction " }}}

function! rst#decrease_indent () " {{{
    call s:save_cursor_position()
    let l:shift_offset = s:vwidth(getline('.'))
    normal! <<
    let l:shift_offset = l:shift_offset - s:vwidth(getline('.'))
    " restore cursor position
    call s:restore_cursor_position(0, -l:shift_offset)

    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'bullet-type')
        call rst#set_bullet('<')
    endif
endfunction " }}}

function! rst#carriage_return () " {{{
    let l:lineobj = s:parse_line('.')
    if !has_key(l:lineobj, 'bullet-type')
        return "\<CR>"
    endif

    if col('.') == strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
        " l:lineobj['text'] == '' or cursor is at text start
        " Just prepend an empty line
        call append(line('.') - 1, '')
        return ""
    endif

    return "\<CR>\<C-o>d0i" . l:lineobj['pspace'] ."\<C-o>:call rst#set_bullet()\<CR>"
endfunction " }}}

function! rst#move_cursor_to_line_start ()
    let l:lineobj = s:parse_line('.')
    let l:logic_line_start = strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
    if col('.') == l:logic_line_start
        call cursor(line('.'), strlen(l:lineobj['pspace']) + 1)
    else
        call cursor(line('.'), l:logic_line_start)
    endif
endfunction
