let s:NO_BULLET = 0
let s:OL_BULLET = 1
let s:UL_BULLET = 2

let s:VALID_RST_SECTION_CHARS = "!\"#$%&'()*+,-./:;<=>?@\[\\\]^_`{|}~"

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

function! s:trim_right (lineobj) " {{{
    let a:lineobj['origin'] = substitute(a:lineobj['origin'], '\v[ \n\r]*$', '', '')
    let a:lineobj['text'] = substitute(a:lineobj['text'], '\v[ \n\r]*$', '', '')
    return a:lineobj
endfunction " }}}

function! s:vwidth (s) " {{{
    return strdisplaywidth(a:s)
endfunction " }}}

function! s:endswith (str, pattern) " {{{
    let l:str_len = strlen(a:str)
    let l:pattern_len = strlen(a:pattern)
    if l:str_len < l:pattern_len
        return 0
    endif

    return (a:str[(l:str_len - l:pattern_len):] ==# a:pattern)
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
    if type(a:row) == type(0)
        let l:ret['row'] = a:row
    else
        let l:ret['row'] = line(a:row)
    endif
    let l:line = getline(a:row)
    let l:ret['origin'] = l:line

    " bullet -*+
    let l:matchobj = matchlist(l:line, '\v(^ *)([-*+])( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['btype'] = s:UL_BULLET
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
        return l:ret
    endif

    " bullet 1.  a.  A.  #.
    let l:matchobj = matchlist(l:line, '\v(^ *)(\d+|[a-zA-Z]+|#)\.( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['btype'] = s:OL_BULLET
        if l:matchobj[2] =~# '\v\d+'
            let l:ret['bnum'] = str2nr(l:matchobj[2])
            let l:ret['bformat'] = '1.'
        elseif l:matchobj[2] =~# '\v[a-z]+'
            let l:ret['bnum'] = char2nr(l:matchobj[2]) - char2nr('a') + 1
            let l:ret['bformat'] = 'a.'
        elseif l:matchobj[2] =~# '\v[A-Z]+'
            let l:ret['bnum'] = char2nr(l:matchobj[2]) - char2nr('A') + 1
            let l:ret['bformat'] = 'A.'
        elseif l:matchobj[2] ==# '#'
            let l:ret['bnum'] = 0
            let l:ret['bformat'] = '#.'
        endif
        let l:ret['bspace'] = l:matchobj[3]
        let l:ret['text'] = l:matchobj[4]
        return l:ret
    endif

    " bullet 1)  a)  A)  #)  (1)  (a)  (A)  (#)
    let l:matchobj = matchlist(l:line, '\v(^ *)(\(?)(\d+|[a-zA-Z]+|#)\)( +)(.*$)')
    if l:matchobj != []
        let l:ret['pspace'] = l:matchobj[1]
        let l:ret['btype'] = s:OL_BULLET
        let l:ret['bformat'] = l:matchobj[2]
        if l:matchobj[3] =~# '\v\d+'
            let l:ret['bnum'] = str2nr(l:matchobj[3])
            let l:ret['bformat'] .= '1)'
        elseif l:matchobj[3] =~# '\v[a-z]+'
            let l:ret['bnum'] = char2nr(l:matchobj[3]) - char2nr('a') + 1
            let l:ret['bformat'] .= 'a)'
        elseif l:matchobj[3] =~# '\v[A-Z]+'
            let l:ret['bnum'] = char2nr(l:matchobj[3]) - char2nr('A') + 1
            let l:ret['bformat'] .= 'A)'
        elseif l:matchobj[3] ==# '#'
            let l:ret['bnum'] = 0
            let l:ret['bformat'] .= '#)'
        endif
        let l:ret['bspace'] = l:matchobj[4]
        let l:ret['text'] = l:matchobj[5]
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
    if has_key(a:lineobj, 'bformat')
        echom a:lineobj['bformat']
        if a:lineobj['bformat'] =~# '1'
            let l:bullet = substitute(a:lineobj['bformat'], '1', a:lineobj['bnum'], '')
        elseif a:lineobj['bformat'] =~# 'a'
            let l:bullet = substitute(a:lineobj['bformat'], 'a', nr2char(a:lineobj['bnum'] + char2nr('a') - 1), '')
        elseif a:lineobj['bformat'] =~# 'A'
            let l:bullet = substitute(a:lineobj['bformat'], 'A', nr2char(a:lineobj['bnum'] + char2nr('A') - 1), '')
        else
            let l:bullet = a:lineobj['bformat']
        endif
    elseif l:level == 0
        let l:bullet = a:lineobj['bnum'] .'.'
    elseif l:level == 1
        let l:bullet = nr2char(a:lineobj['bnum'] + char2nr('A') - 1) .')'
    elseif l:level == 2
        let l:bullet = '('. nr2char(a:lineobj['bnum'] + char2nr('a') - 1) .')'
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

    if get(l:ref_line, 'btype', s:NO_BULLET) == s:NO_BULLET
        " reference line is not a list item, nothing to reference
        if a:lineobj['btype'] == s:OL_BULLET
            let a:lineobj['bnum'] = 1
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
                    let a:lineobj['bnum'] = l:ref_line['bnum'] + 1
                elseif a:lineobj['follow'] == '<'
                    let a:lineobj['pspace'] = repeat(' ', l:pspace - (l:myindent - l:align))
                    let a:lineobj['bnum'] = 1
                endif
            elseif a:lineobj['btype'] == s:OL_BULLET
                let a:lineobj['bnum'] = 1
            endif
            return

        elseif a:lineobj['follow'] == '<'
            " try to align to reference line
            let a:lineobj['pspace'] = repeat(' ', l:align)
            let a:lineobj['btype'] = l:ref_line['btype']
            if l:ref_line['btype'] == s:OL_BULLET
                let a:lineobj['bnum'] = l:ref_line['bnum'] + 1
            endif
            return

        else
            " try to indent to reference line
            let a:lineobj['pspace'] = repeat(' ', l:indent)
            let a:lineobj['btype'] = s:OL_BULLET
            let a:lineobj['bnum'] = 1
            return

        endif

    elseif l:ref_line['btype'] == s:OL_BULLET
        " reference line is an ordered list item
        let a:lineobj['btype'] = s:OL_BULLET
        let a:lineobj['bnum'] = l:ref_line['bnum'] + 1
        if has_key(l:ref_line, 'bformat')
            let a:lineobj['bformat'] = l:ref_line['bformat']
        endif
        return
    endif

    " reference line is an unordered list item
    let a:lineobj['btype'] = s:UL_BULLET
endfunction " }}}

function! s:toggle_bullet (lineobj) " {{{
    if get(a:lineobj, 'btype', s:NO_BULLET) == s:NO_BULLET
        let a:lineobj['btype'] = s:UL_BULLET

    elseif a:lineobj['btype'] == s:UL_BULLET
        let a:lineobj['btype'] = s:OL_BULLET
        let a:lineobj['bnum'] = 1

    elseif a:lineobj['btype'] == s:OL_BULLET
        let a:lineobj['btype'] = s:UL_BULLET
        unlet a:lineobj['bnum']

    endif
endfunction " }}}

function! s:write_line (lineobj) " {{{
    let l:_ = a:lineobj
    call s:save_cursor_position()
    if get(l:_, 'btype', s:NO_BULLET) == s:NO_BULLET
        call setline(l:_['row'], l:_['pspace'] . l:_['text'])
    elseif l:_['btype'] == s:UL_BULLET
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
    if has_key(l:lineobj, 'btype')
        unlet l:lineobj['btype']
        call s:write_line(l:lineobj)
    endif
endfunction " }}}

function! rst#increase_indent () " {{{
    call s:save_cursor_position()
    normal! >>
    call s:restore_cursor_position(0, &shiftwidth)

    let l:lineobj = s:parse_line('.')
    if has_key(l:lineobj, 'btype')
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
    if has_key(l:lineobj, 'btype')
        call rst#set_bullet('<')
    endif
endfunction " }}}

function! rst#carriage_return () " {{{
    let l:lineobj = s:parse_line('.')
    if !has_key(l:lineobj, 'btype')
        " current line is not a list item

        " here comes a literal block
        if s:endswith(l:lineobj['origin'], '::')
            return "\<CR>\<CR>". repeat(' ', &softtabstop)
        endif
        return "\<CR>"
    endif

    if col('.') == strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
        " l:lineobj['text'] == '' or cursor is at text start
        " Just prepend an empty line
        call append(line('.') - 1, '')
        return ""
    endif

    " here comes a literal block
    if s:endswith(l:lineobj['origin'], '::')
        return "\<CR>\<CR>\<ESC>d0i" .
            \repeat(' ',
            \s:vwidth(l:lineobj['origin']) - s:vwidth(l:lineobj['text']) + &softtabstop)
    endif

    return "=\<LEFT>\<CR>\<ESC>d0i" . l:lineobj['pspace'] ."\<ESC>:call rst#set_bullet()\<CR>^Ws"
endfunction " }}}

function! rst#move_cursor_to_line_start (...) range " {{{
    if a:0 == 1 && a:1 ==# 'v'
        normal! gv
    endif

    let l:lineobj = s:parse_line('.')
    let l:logic_line_start = strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
    if col('.') == l:logic_line_start
        call cursor(line('.'), strlen(l:lineobj['pspace']) + 1)
    else
        call cursor(line('.'), l:logic_line_start)
    endif
endfunction " }}}

function! s:is_title_line (text) " {{{
    return a:text =~# '\v^(['. s:VALID_RST_SECTION_CHARS .'])\1*$'
endfunction " }}}

function! s:get_title_line (row) " {{{
    let l:lineobj = s:trim_right(s:parse_line(a:row))
    if strlen(l:lineobj['origin']) == 0
        " cursor is on empty line, no need to check more
        return l:lineobj
    endif

    if strlen(l:lineobj['text']) == 0
        " this line is an empty list item, make it a normal text
        let l:lineobj['text'] = l:lineobj['origin']
        return l:lineobj
    endif

    if !s:is_title_line(l:lineobj['origin'])
        " this line is not special, return it
        return l:lineobj
    endif

    " this line is a title line, we have to check which line we are on
    let l:last_lineobj = s:trim_right(s:parse_line(l:lineobj['row'] - 1))
    if s:is_title_line(l:last_lineobj['origin'])
        " last line is also a title line?
        " looks like the user screwed up the document, we won't handle it
        return l:lineobj
    endif

    if l:last_lineobj['origin'] !=# ''
        " last line is not an empty line, we found the title line
        return l:last_lineobj
    endif

    " last line is an empty line, we should check for next 2 line
    let l:next2_lineobj = s:trim_right(s:parse_line(l:lineobj['row'] + 2))
    if s:is_title_line(l:next2_lineobj['origin'])
        " next 2 line is a title line, we just assume the next line is the
        " title line
        return s:parse_line(l:lineobj['row'] + 1)
    endif

    " really don't know how to handle this situation
    return l:lineobj
endfunction " }}}

function! rst#make_title (level) " {{{
    if a:level < 1 || a:level > 6
        return
    endif

    let l:lineobj = s:get_title_line('.')
    let l:text_length = s:vwidth(l:lineobj['text'])
    if l:text_length == 0
        " empty title? it doesn't make sense
        return
    endif

    let l:title_line = repeat("=-`'.~*"[a:level - 1], l:text_length + a:level - 1)

    let l:lastline_row = l:lineobj['row'] - 1
    let l:lastline = getline(l:lastline_row)
    if s:is_title_line(l:lastline)
        " last line may be a level 1 title line, destroy it
        execute "silent ". l:lastline_row .','. l:lastline_row .'delete _'
        let l:lineobj['row'] -= 1
    endif

    if getline(l:lineobj['row'] - 1) !=# ''
        " last line is neither title line, nor empty line
        " we should insert an empty line
        call append(l:lineobj['row'] - 1, '')
        let l:lineobj['row'] += 1
    endif

    if a:level == 1
        " give you a pretty title
        call append(l:lineobj['row'] - 1, l:title_line)
        let l:lineobj['row'] += 1
    endif

    call setline(l:lineobj['row'], l:lineobj['text'])
    let l:nextline = getline(l:lineobj['row'] + 1)
    if s:is_title_line(l:nextline) || l:nextline ==# ''
        " next line is a transition or title line, destroy it
        call setline(l:lineobj['row'] + 1, l:title_line)
    else
        " next line is normal text, keep it
        call append(l:lineobj['row'], l:title_line)
    endif
endfunction " }}}

function! rst#move_cursor_to_next_title (...) range " {{{
    if a:0 == 1 && a:1 ==# 'v'
        normal! gv
    endif

    let l:row = line('.') + 2
    while l:row <= line('$')
        let l:line = getline(l:row)
        if s:is_title_line(l:line)
            let l:lastline = getline(l:row - 1)
            if l:lastline !=# ''
                call cursor(l:row - 1, 1)
                return
            endif
        endif
        let l:row += 1
    endwhile
endfunction " }}}

function! rst#move_cursor_to_last_title (...) range " {{{
    if a:0 == 1 && a:1 ==# 'v'
        normal! gv
    endif

    let l:row = line('.') - 1
    while l:row > 0
        let l:line = getline(l:row)
        if s:is_title_line(l:line)
            let l:lastline = getline(l:row - 1)
            if l:lastline !=# ''
                call cursor(l:row - 1, 1)
                return
            endif
        endif
        let l:row -= 1
    endwhile
endfunction " }}}

function! rst#tab() " {{{
    let l:lineobj = s:parse_line('.')
    if !has_key(l:lineobj, 'btype')
        return "\<TAB>"
    endif

    let l:logic_line_start = strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
    if col('.') == l:logic_line_start
        return "\<C-\>\<C-o>:call rst#increase_indent()\<CR>"
    else
        return "\<TAB>"
    endif
endfunction " }}}

function! rst#shift_tab() " {{{
    let l:lineobj = s:parse_line('.')
    let l:logic_line_start = strlen(l:lineobj['origin']) - strlen(l:lineobj['text']) + 1
    if col('.') == l:logic_line_start
        call rst#decrease_indent()
    endif
endfunction " }}}

function! rst#join_two_lines () " {{{
    let l:nln = line('.') + 1
    if l:nln <= line('$')
        let l:lineobj = s:parse_line(l:nln)
        call setline(l:nln, l:lineobj['text'])
        normal! J
    endif
endfunction " }}}
