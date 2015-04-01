" vim:fdm=marker
" ============================================================================
" File:        rst.vim
" Description: Pi314's rst plugin
" Maintainer:  Pi314 <michael66230@gmail.com>
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
" ============================================================================
"
setlocal softtabstop=2
setlocal shiftwidth=2

" Prevent Complete Function Error
setlocal indentexpr=

" Add a line under a rst title
nnoremap <buffer> <silent> t0 :call Title("==")<CR>
nnoremap <buffer> <silent> t1 :call Title("=")<CR>
nnoremap <buffer> <silent> t2 :call Title("-")<CR>
nnoremap <buffer> <silent> t3 :call Title("~")<CR>
nnoremap <buffer> <silent> t4 :call Title('"')<CR>
nnoremap <buffer> <silent> t5 :call Title("'")<CR>
nnoremap <buffer> <silent> t6 :call Title("`")<CR>
let s:title_pattern = '^\([^a-zA-Z 	]\)\1*$'

function! Title(i_title_char) " {{{
    let title_char = a:i_title_char
    let t0 = 0

    if l:title_char ==# "=="
        let t0 = 1
        let l:title_char = "="

    elseif len(l:title_char) != 1
        return

    endif

    let orig_row = line('.')
    let orig_col = col('.')

    let tmp = ParseBullet(getline('.'))
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']
    let clc_origin = l:tmp['origin']

    if l:clc_bullet != '' || l:clc_pspace != ''
        let l:clc_origin = l:clc_text
        call setline('.', l:clc_origin)
    endif

    if l:clc_origin =~# s:title_pattern
        " the cursor is on the title line
        if getline(l:orig_row + 2) =~# s:title_pattern
            " the cursor is on the t0 upper line
            call cursor(l:orig_row + 1, col('.'))

        else
            " the cursor is on the t0 lower line
            call cursor(l:orig_row - 1, col('.'))

        endif

    endif

    if getline(line('.') - 1) =~# s:title_pattern
        " remove the t0 upper line
        normal! kdd
        call cursor(line('.'), l:orig_col)
    endif

    let line_length = strdisplaywidth(l:clc_origin)
    let title_string = repeat(l:title_char, l:line_length < 4 ? 4 : l:line_length)
    let next_line_content = getline(line('.') + 1)

    if l:next_line_content ==# ''
        call append('.', l:title_string)

    elseif l:next_line_content =~# s:title_pattern
        call setline(line('.')+1, l:title_string)

    else
        call append('.', '')
        call append('.', l:title_string)

    endif

    if l:t0
        call append(line('.') - 1, l:title_string)
    else
        call cursor(l:orig_row, col('.'))
    endif

endfunction " }}}

nnoremap <buffer> <silent> < :call ShiftIndent("LEFT")<CR>
nnoremap <buffer> <silent> > :call ShiftIndent("RIGHT")<CR>
vnoremap <buffer> <silent> < :call ShiftIndent("LEFT")<CR>gv
vnoremap <buffer> <silent> > :call ShiftIndent("RIGHT")<CR>gv
inoremap <buffer> <silent> <C-]> <ESC>:call ShiftIndent("RIGHT")<CR>A

inoremap <buffer> <silent> <TAB> <C-r>=Tab("NORMAL")<CR>
inoremap <buffer> <silent> <S-TAB> <C-r>=Tab("SHIFT")<CR>
function! Tab (tab_type) " {{{
    let cln = line('.')
    let clc = getline(l:cln)
    let tmp = ParseBullet(l:clc)
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']

    let direction = { "NORMAL": "RIGHT", "SHIFT": "LEFT"}[a:tab_type]

    echom '['. l:clc .']'
    echom '['. l:clc_pspace .']'
    echom '['. l:clc_bullet .']'
    echom '['. l:clc_text .']'
    echom '{'. strpart(l:clc, 0, col('.')-1 ) .'}'
    echom '{'. '^'. l:clc_pspace . l:clc_bullet .' *$' .'}'
    echom '===================='

    let clc_before_cursor = substitute(strpart(l:clc, 0, col('.')-1 ), ' *$', '', '')

    if l:clc_bullet == ''
        return "\<TAB>"

    elseif l:clc_bullet != '' && l:clc_before_cursor ==# l:clc_pspace . l:clc_bullet
        if l:clc_text == ''
            return "\<ESC>:call ShiftIndent('". direction ."')\<CR>A"
        else
            return "\<ESC>:call ShiftIndent('". direction ."')\<CR>^Wi"
        endif

    endif

    return "\<TAB>"

endfunction " }}}

let s:blpattern = '^ *[-*+] \+\([^ ].*\)\?$'
let s:elpattern1 = '^ *\d\+\. \+\([^ ].*\)\?$'          " 1.
let s:elpattern2 = '^ *#\. \+\([^ ].*\)\?$'             " #.
let s:elpattern3 = '^ *[a-zA-Z]\. \+\([^ ].*\)\?$'      " a.    A.
let s:elpattern4 = '^ *(\?\d\+) \+\([^ ].*\)\?$'        " 1)    (2)
let s:elpattern5 = '^ *(\?[a-zA-Z]) \+\([^ ].*\)\?$'    " a)    (A)

function! GetLastReferenceLine (cln, pspace_num) " {{{
    let tmp = ParseBullet(getline(a:cln))
    let clc_pspace = repeat(' ', a:pspace_num)
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']

    if a:pspace_num == 0 && l:clc_text == '' && l:clc_bullet == ''
        let case = 1
    else
        let case = 2
    endif

    " current line is empty
    let llc_pspace = ''
    let llc_bullet = ''
    let empty_line_count = 0
    let i = a:cln - 1

    while l:i > 0
        let tmp = ParseBullet(getline(l:i))
        let llc_pspace = l:tmp['pspace']
        let llc_bullet = l:tmp['bullet']
        let llc_text   = l:tmp['text']

        if l:llc_text == '' && l:llc_bullet == ''
            let empty_line_count += 1
            " two continuous empty line means the list is seperated
            if l:empty_line_count == 2
                return {'bullet': '', 'pspace': ''}
            endif
            let l:i = l:i - 1
            continue
        else
            let empty_line_count = 0
        endif

        if l:llc_text != '' && l:llc_bullet == '' && strlen(l:llc_pspace) <= a:pspace_num
            " non-list-item text & indent <= current line
            return {'bullet': '', 'pspace': ''}
        endif

        if l:llc_bullet != ''
            " a list item
            if l:case == 1
                " current line is empty, just follow it
                return {'bullet': l:llc_bullet, 'pspace': l:llc_pspace}

            elseif l:case == 2
                " current line is not empty, check more
                if strlen(l:llc_pspace) == a:pspace_num
                    " same indent, follow it
                    return {'bullet': l:llc_bullet, 'pspace': l:llc_pspace}

                elseif strlen(l:llc_pspace) < a:pspace_num
                    " current line indents more, so the list breaks by the
                    " line
                    return {'bullet': '', 'pspace': ''}

                endif
            endif

        endif

        let l:i = l:i - 1
    endwhile

    return {'bullet': l:llc_bullet, 'pspace': l:llc_pspace}

endfunction " }}}

function! GetBulletLeader (bullet, pspace_num) " {{{
    if a:bullet =~# '^[-*+]$'
        return "*-+"[(a:pspace_num / &shiftwidth) % 3]
    endif

    let is_enumerate_list_item = 0

    if a:bullet == '#.'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^\d\+\.$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^[a-z]\.$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^[A-Z]\.$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^\d\+)$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^(\d\+)$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^[a-z])$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^[A-Z])$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^([a-z])$'
        let is_enumerate_list_item = 1

    elseif a:bullet =~# '^([A-Z])$'
        let is_enumerate_list_item = 1

    endif

    if l:is_enumerate_list_item
        return ['1.', 'A.', 'a.', '1)', 'A)', 'a)', '(1)', '(A)', '(a)'][(a:pspace_num / &shiftwidth) % 9]
    endif

    return ''
endfunction " }}}

function! ShiftIndent (direction) " {{{
    let cln = line('.')
    let clc = getline(l:cln)
    let tmp = ParseBullet(l:clc)
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']
    let remain_space = strlen(l:clc_pspace) % (&shiftwidth)

    if l:clc_text ==# '' && l:clc_bullet ==# ''
        return
    endif

    if a:direction ==# "LEFT"
        let pspace_num = strlen(l:clc_pspace) - ((l:remain_space != 0) ? (l:remain_space) : &shiftwidth)
        let l:pspace_num = (l:pspace_num < 0) ? 0 : (l:pspace_num)

    else
        let pspace_num = strlen(l:clc_pspace) + ((l:remain_space != 0) ? (&shiftwidth - l:remain_space) : &shiftwidth)

    endif

    let result_line = repeat(' ', l:pspace_num) . l:clc_text

    if l:clc_bullet != ''
        let tmp = GetLastReferenceLine(l:cln, l:pspace_num)
        let llc_bullet = l:tmp['bullet']
        let llc_pspace = l:tmp['pspace']

        if l:pspace_num == 0 && strlen(l:llc_pspace) > 0
            let l:llc_bullet = ''
        endif

        if l:llc_bullet == ''
            let new_bullet = GetBulletLeader(l:clc_bullet, l:pspace_num)

        elseif l:llc_bullet =~# '^[-*+]$'
            " last line is a bulleted list item
            let new_bullet = "*-+"[(l:pspace_num / &shiftwidth) % 3]

        elseif l:llc_bullet == '#.'
            " last line is a (lazy) enumerate list item
            let new_bullet = '#.'

        elseif l:llc_bullet =~# '^\d\+\.$'
            " last line is a enumerate list item
            let new_bullet = (l:llc_bullet + 1) .'.'

        elseif l:llc_bullet =~# '^[a-zA-Z]\.$'
            let new_bullet = nr2char( char2nr(l:llc_bullet) + 1 ) .'.'

        elseif l:llc_bullet =~# '^\d\+)$'
            let new_bullet = ( matchstr(l:llc_bullet, '\(^(\?\)\@<=\d\+\()$\)\@=') + 1 ) .')'

        elseif l:llc_bullet =~# '^(\d\+)$'
            let new_bullet = '('. ( matchstr(l:llc_bullet, '\(^(\?\)\@<=\d\+\()$\)\@=') + 1 ) .')'

        elseif l:llc_bullet =~# '^[a-zA-Z])$'
            let new_bullet = nr2char( char2nr( matchstr(l:llc_bullet, '\(^(\?\)\@<=[a-zA-Z]\()$\)\@=')) + 1 ) .')'

        elseif l:llc_bullet =~# '^([a-zA-Z])$'
            let new_bullet = '('. nr2char( char2nr( matchstr(l:llc_bullet, '\(^(\?\)\@<=[a-zA-Z]\()$\)\@=')) + 1 ) .')'

        else
            let new_bullet = "*-+"[(l:pspace_num / &shiftwidth) % 3]

        endif
        let bullet_space = repeat(' ', &softtabstop - ((l:pspace_num + strlen(l:new_bullet)) % (&softtabstop)) )
        let result_line = repeat(' ', l:pspace_num). l:new_bullet . l:bullet_space . l:clc_text

    endif

    call setline('.', l:result_line)
    normal! ^

endfunction " }}}

function! ParseBullet (line) " {{{
    let pspace = matchstr(a:line, '^ *')
    let bullet = ''
    if a:line =~# s:blpattern
        let bullet = matchstr(a:line, '\(^ *\)\@<=[-*+]\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *[-*+]\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text   = matchstr(a:line, '\(^ *[-*+] \+\)\@<=\([^ ].*\)\?$')

    elseif a:line =~# s:elpattern1
        let bullet = matchstr(a:line, '\(^ *\)\@<=\d\+\.\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *\d\+\.\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text = matchstr(a:line, '\(^ *\d\+\. \+\)\@<=\([^ ].*\)\?$')

    elseif a:line =~# s:elpattern2
        let bullet = matchstr(a:line, '\(^ *\)\@<=#\.\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *#\.\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text = matchstr(a:line, '\(^ *#\. \+\)\@<=\([^ ].*\)\?$')

    elseif a:line =~# s:elpattern3
        let bullet = matchstr(a:line, '\(^ *\)\@<=[a-zA-Z]\.\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *[a-zA-Z]\.\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text = matchstr(a:line, '\(^ *[a-zA-Z]\. \+\)\@<=\([^ ].*\)\?$')

    elseif a:line =~# s:elpattern4
        let bullet = matchstr(a:line, '\(^ *\)\@<=(\?\d\+)\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *(\?\d\+)\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text = matchstr(a:line, '\(^ *(\?\d\+) \+\)\@<=\([^ ].*\)\?$')

    elseif a:line =~# s:elpattern5
        let bullet = matchstr(a:line, '\(^ *\)\@<=(\?[a-zA-Z])\( \+\([^ ].*\)\?$\)\@=')
        let bspace = matchstr(a:line, '\(^ *(\?[a-zA-Z])\)\@<= \+\(\([^ ].*\)\?$\)\@=')
        let text = matchstr(a:line, '\(^ *(\?[a-zA-Z]) \+\)\@<=\([^ ].*\)\?$')

    else
        let bullet = ''
        let bspace = ''
        let text = matchstr(a:line, '\(^ *\)\@<=[^ ].*$')

    endif

    "echom '['. l:pspace .']['. l:bullet .']['. l:text .']'
    return {'pspace': (l:pspace), 'bullet': (l:bullet), 'text': (l:text), 'origin': (a:line), 'bspace': (l:bspace)}
endfunction " }}}

inoremap <buffer> <silent> <leader>b <ESC>:call CreateBullet()<CR>a
nmap     <buffer> <silent> <leader>b A<leader>b<ESC>
vnoremap <buffer> <silent> <leader>b :call CreateBullet()<CR>gv
function! CreateBullet () " {{{
    let cln = line('.')
    let clc = getline(l:cln)
    let tmp = ParseBullet(l:clc)
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']
    let pspace_num = strlen(l:clc_pspace)
    let remain_space = l:pspace_num % (&shiftwidth)

    let pspace_num = l:pspace_num - l:remain_space

    let tmp = GetLastReferenceLine(l:cln, l:pspace_num)
    let llc_bullet = l:tmp['bullet']
    let llc_pspace = l:tmp['pspace']

    if l:llc_bullet != ''
        let l:pspace_num = strlen(l:llc_pspace)
    endif

    if l:llc_bullet == ''
        if l:clc_bullet == ''
            let l:clc_bullet = '*'
        elseif l:clc_bullet =~# '^[-*+]$'
            let l:clc_bullet = '1.'
        elseif l:clc_bullet =~# '^\(\(\d\+\|[a-zA-Z]\|#\)\.\|(\?\(\d\+\|[a-zA-Z]\))\)$'
            let l:clc_bullet = '*'
        endif
        let new_bullet = GetBulletLeader(l:clc_bullet, l:pspace_num)

    elseif l:llc_bullet =~# '^[-*+]$'
        " last line is a bulleted list item
        let new_bullet = "*-+"[(l:pspace_num / &shiftwidth) % 3]

    elseif l:llc_bullet == '#.'
        " last line is a (lazy) enumerate list item
        let new_bullet = '#.'

    elseif l:llc_bullet =~# '^\d\+\.$'
        " last line is a enumerate list item
        let new_bullet = (l:llc_bullet + 1) .'.'

    elseif l:llc_bullet =~# '^[a-zA-Z]\.$'
        let new_bullet = nr2char( char2nr(l:llc_bullet) + 1 ) .'.'

    elseif l:llc_bullet =~# '^\d\+)$'
        let new_bullet = ( matchstr(l:llc_bullet, '\(^(\?\)\@<=\d\+\()$\)\@=') + 1 ) .')'

    elseif l:llc_bullet =~# '^(\d\+)$'
        let new_bullet = '('. ( matchstr(l:llc_bullet, '\(^(\?\)\@<=\d\+\()$\)\@=') + 1 ) .')'

    elseif l:llc_bullet =~# '^[a-zA-Z])$'
        let new_bullet = nr2char( char2nr( matchstr(l:llc_bullet, '\(^(\?\)\@<=[a-zA-Z]\()$\)\@=')) + 1 ) .')'

    elseif l:llc_bullet =~# '^([a-zA-Z])$'
        let new_bullet = '('. nr2char( char2nr( matchstr(l:llc_bullet, '\(^(\?\)\@<=[a-zA-Z]\()$\)\@=')) + 1 ) .')'

    else
        let new_bullet = "*-+"[(l:pspace_num / &shiftwidth) % 3]

    endif

    let bullet_space = repeat(' ', &softtabstop - ((l:pspace_num + strlen(l:new_bullet)) % (&softtabstop)) )
    let result_line = repeat(' ', l:pspace_num). l:new_bullet . l:bullet_space . l:clc_text
    call setline(l:cln, l:result_line)
    call cursor(l:cln, strlen(l:result_line))

endfunction " }}}

inoremap <buffer> <silent> <CR> <C-r>=NewLine()<CR>
nmap <buffer> <silent> o A<CR>
function! NewLine () " {{{
    let cln = line('.')
    let clc = getline(l:cln)
    let tmp = ParseBullet(l:clc)
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_text   = l:tmp['text']
    let clc_bspace = l:tmp['bspace']
    let pspace_num = strlen(l:clc_pspace)
    let remain_space = l:pspace_num % (&softtabstop)

    let pspace_num = l:pspace_num - l:remain_space

    if l:clc_bullet == ''
        " no bullet item
        if strpart(l:clc_text, 0, col('.')-1) =~# '^.*:: *$'
            " abc :: _(abc)?
            return "\<CR>\<CR>\<CR>\<ESC>k0Di". l:clc_pspace . repeat(' ', &softtabstop) . "\<ESC>JI"
        elseif l:clc_pspace == '' && strpart(l:clc_text, 0, col('.')-1) =~# '^:[^:]\+:'
            " ^:abc:_(abc)?
            return "\<CR>". repeat(' ', &softtabstop)
        else
            return "\<CR>"
        endif
    else
        " bullet item
        if l:clc_text == ''
            " empty bullet
            let destroy_bullet = 0
            if l:cln == 1
                let l:destroy_bullet = 1
            else
                let llc = getline(l:cln - 1)
                if l:llc =~# "^ *$"
                    let l:destroy_bullet = 1
                else
                    let l:destroy_bullet = 0
                endif
            endif

            if l:destroy_bullet == 1
                call setline(l:cln, '')
                return ""
            else
                return "\<ESC>O\<ESC>jA"
            endif
            
        elseif strpart(l:clc, 0, col('.')-1) =~# '^.*:: *$'
            " 1. abc:: _
            let bspace = repeat(' ', strlen(l:clc_bullet))
            let bullet_space = repeat(' ', &softtabstop - ((strlen(l:clc_pspace) + strlen(l:clc_bullet)) % (&softtabstop)) )
            return "\<CR>\<CR>\<CR>\<ESC>k0Di".l:clc_pspace.l:bspace.l:bullet_space . repeat(' ', &softtabstop)."\<ESC>JI"

        elseif l:clc_text != ''
            if l:clc[ (col('.') - 1) : ] == ''
                " 1.  abcd_
                return "\<CR>\<ESC>d0:call CreateBullet()\<CR>a"
            elseif l:clc[ (col('.') - 1) : ] ==# l:clc_text
                " 1.  _abcd
                return "\<ESC>O\<ESC>jWi"
            else
                " 1.  ab_cd
                return "\<CR>\<CR>\<ESC>d0k:call CreateBullet()\<CR>Ji"
            endif

        endif

    endif

endfunction " }}}
nmap <buffer> <silent> O :call UpperNewLine()<CR>A
function! UpperNewLine () " {{{
    let cln = line('.')
    let clc = getline(l:cln)
    let tmp = ParseBullet(l:clc)
    let clc_pspace = l:tmp['pspace']
    let clc_bullet = l:tmp['bullet']
    let clc_bspace = l:tmp['bspace']
    let clc_text   = l:tmp['text']
    call append(l:cln - 1, '')
    call cursor(l:cln, 1)
    call setline(l:cln, l:clc_pspace . l:clc_bullet . l:clc_bspace)
endfunction " }}}

nnoremap <buffer> <silent> tj :call FindNextTitle()<CR>
nnoremap <buffer> <silent> tk :call FindLastTitle()<CR>
function! FindNextTitle () " {{{
    let i = line('.') + 1
    while l:i <= line('$')
        if getline(l:i) =~# s:title_pattern
            call cursor(l:i, 1)
            break
        endif
        let l:i = l:i + 1
    endwhile

endfunction " }}}

function! FindLastTitle () " {{{
    let i = line('.') - 1
    while l:i >= 1
        if getline(l:i) =~# s:title_pattern
            call cursor(l:i, 0)
            break
        endif
        let l:i = l:i - 1
    endwhile
endfunction " }}}

