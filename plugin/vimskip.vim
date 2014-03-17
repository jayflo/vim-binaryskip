" vimskip.vim - move horizontally binarily
" Maintainer:   Jaret Flores <github.com/jayflo>
" Version:      0.1

" ====[ Options ]====
if (exists("g:vimskip_disable") && g:vimskip_disable)
    finish
end
let g:vimskip_disable = 0

let g:vimskip_disable_default_maps      = get(g:, 'vimskip_disable_default_maps', 0)
let g:vimskip_multiplier                = get(g:, 'vimskip_multiplier', 0.5)
let g:vimskip_mode                      = get(g:, 'vimskip_mode', "normal")
let g:vimskip_wraptocenter              = get(g:, 'vimskip_wraptocenter', 0)
let g:vimskip_wraptomiddleline          = get(g:, 'vimskip_wraptomiddleline', '0')
let g:vimskip_split_passthroughcenter   = get(g:, 'vimskip_split_passthroughcenter', 1)
let g:vimskip_helix                     = get(g:, 'vimskip_helix', 0)
let g:vimskip_ignore_initial_ws         = get(g:, 'vimskip_ignore_initial_ws', 1)
let g:vimskip_ignore_trailing_ws        = get(g:, 'vimskip_ignore_trailing_ws', 1)
let g:vimskip_mapforwardskip            = get(g:, 'vimskip_mapforwardskip', 's')
let g:vimskip_mapbackwardskip           = get(g:, 'vimskip_mapbackwardskip', 'S')
let g:vimskip_maptocenter               = get(g:, 'vimskip_maptocenter', 'gs')

let modes = ["normal", "split", "fixed", "anti"]
if !(index(modes, g:vimskip_mode) >= 0)
    let g:vimskip_mode = "normal"
end

" ====[ Script Variables ]====
let s:factor = g:vimskip_multiplier

if g:vimskip_helix
    let s:safedown = "j"
    let s:safeup = "k"
    let s:safenext = 1
    let s:safeprevious = -1
else
    let s:safedown = ""
    let s:safeup = ""
    let s:safenext = 0
    let s:safeprevious = 0
end

let s:switchmode = "normal"
let s:vertmode = 0

let s:left = "h"
let s:right = "l"
let s:up = "k"
let s:down = "j"
let s:current = 0

" ====[ Getters ]====
function! s:Cursor()
    return getpos('.')[2]
endfunction

function! s:Line(offset)
    return getline(line('.') + a:offset)
endfunction

function! s:DistanceTo(destination)
    return abs(s:Cursor()-a:destination)
endfunction

function! s:Scale(...)
    if a:0 > 1
        return float2nr(ceil(a:1 * 1.0 * a:2))
    else
        return float2nr(ceil(a:1 * 1.0 * s:factor))
    end
endfunction

function! s:BeginningOf(line)
    if g:vimskip_ignore_initial_ws
        return match(a:line,'\S')+1
    else
        return 0
    end
endfunction

function! s:EndOf(line)
    if g:vimskip_ignore_trailing_ws
        return strlen(substitute(a:line,'\s\+$','','g'))
    else
        return strlen(a:line)
    end
endfunction

function! s:CenterOf(line)
    let l:beginningofline = s:BeginningOf(a:line)
    return l:beginningofline + s:Scale(s:EndOf(a:line)-l:beginningofline, 0.5)
endfunction

" ====[ Setters ]====
"          int     , str
function! s:Skip(distance, direction)
    execute "normal! ".string(a:distance).a:direction
endfunction

function! s:ToCenter(...)
    execute "normal! 0".a:1
    call s:Skip(s:CenterOf(s:Line(s:current)), s:right)
endfunction

function! s:Wrap(destination)
    if a:destination == "tobeginning"
        if g:vimskip_ignore_initial_ws
            execute "normal! ".s:safedown."^"
        else
            execute "normal! ".s:safedown."0"
        end
    elseif a:destination == "toend"
        if g:vimskip_ignore_trailing_ws
            execute "normal! ".s:safeup."g_"
        else
            execute "normal! ".s:safeup."$"
        end
    elseif a:destination == "tocenterfrombeginning"
        call s:ToCenter(s:safeup)
    elseif a:destination == "tomiddle"
        execute 'normal! M'
    elseif a:destination == "tobottom"
        execute "normal! L"
    elseif a:destination == "totop"
        execute "normal! H"
    else
        call s:ToCenter(s:safedown)
    end
endfunction

" ====[ Normal Mode ]====
function! s:NormalForward()
    let l:dist = s:DistanceTo(s:EndOf(s:Line(s:current)))
    if l:dist
        call s:Skip(s:Scale(l:dist), s:right)
    else
        if g:vimskip_wraptocenter
            call s:Wrap("tocenterfromend")
        else
            call s:Wrap("tobeginning")
        end
    end
endfunction

function! s:NormalBackward()
    let l:dist = s:DistanceTo(s:BeginningOf(s:Line(s:current)))
    if l:dist
        call s:Skip(s:Scale(l:dist), s:left)
    else
        if g:vimskip_wraptocenter
            call s:Wrap("tocenterfrombeginning")
        else
            call s:Wrap("toend")
        end
    end
endfunction

" ====[ Split Mode ]====
function! s:SplitForward()
    let l:cursor = s:Cursor()
    let l:center= s:CenterOf(s:Line(s:current))

    if l:cursor < l:center
        call s:Skip(s:Scale(l:center-l:cursor), s:right)
    elseif l:cursor > l:center
        let l:dist = s:DistanceTo(s:EndOf(s:Line(s:current)))

        if l:dist
            call s:Skip(s:Scale(l:dist), s:right)
        else
            if g:vimskip_wraptocenter
                call s:Wrap('tocenterfromend')
            else
                call s:Wrap("tobeginning")
            end
        end
    else
        if g:vimskip_split_passthroughcenter
            call s:Skip(s:Scale(s:DistanceTo(s:EndOf(s:Line(s:current)))), s:right)
        else
            call s:Wrap("tobeginning")
        end
    end
endfunction

function! s:SplitBackward()
    let l:cursor = s:Cursor()
    let l:center= s:CenterOf(s:Line(s:current))

    if l:cursor > l:center
        call s:Skip(s:Scale(l:cursor-l:center), s:left)
    elseif l:cursor < l:center
        let l:dist = s:DistanceTo(s:BeginningOf(s:Line(s:current)))

        if l:dist
            call s:Skip(s:Scale(l:dist), s:left)
        else
            if g:vimskip_wraptocenter
                call s:Wrap("tocenterfrombeginning")
            else
                call s:Wrap("toend")
            end
        end
    else
        if g:vimskip_split_passthroughcenter
            call s:Skip(s:Scale(s:DistanceTo(s:BeginningOf(s:Line(s:current)))), s:left)
        else
            call s:Wrap("toend")
        end
    end
endfunction

" ====[ Antipodal Mode ]====
function! s:AntiForward()
    let l:cursor = s:Cursor()
    let l:center= s:CenterOf(s:Line(s:current))

    if l:cursor < l:center
        call s:Skip(s:Scale(l:center-l:cursor), s:right)
    else
        let l:distancetoend = s:DistanceTo(s:EndOf(s:Line(s:current)))
        let l:beginningofline = s:BeginningOf(s:Line(s:safenext))
        if g:vimskip_helix
            let l:center = s:CenterOf(s:Line(s:safenext))
        end
        let l:skipdist = s:Scale(l:distancetoend + (l:center - l:beginningofline))

        if l:skipdist <= l:distancetoend
            call s:Skip(l:skipdist, s:right)
        else
            if g:vimskip_wraptocenter
                call s:Wrap("tocenterfromend")
            else
                call s:Wrap("tobeginning")
            end
            call s:Skip(l:skipdist - l:distancetoend, s:right)
        end
    end
endfunction

function! s:AntiBackward()
    let l:cursor = s:Cursor()
    let l:center= s:CenterOf(s:Line(s:current))

    if l:cursor > l:center
        call s:Skip(s:Scale(l:cursor-l:center), s:left)
    else
        let l:distancetobeginning = s:DistanceTo(s:BeginningOf(s:Line(s:current)))
        let l:endofline = s:EndOf(s:Line(s:safeprevious))
        if g:vimskip_helix
            let l:center = s:CenterOf(s:Line(s:safeprevious))
        end
        let l:skipdist = s:Scale(l:distancetobeginning + (l:endofline-l:center))

        if l:skipdist <= l:distancetobeginning
            call s:Skip(l:skipdist, s:left)
        else
            if g:vimskip_wraptocenter
                call s:Wrap("tocenterfrombeginning")
            else
                call s:Wrap("toend")
            end
            call s:Skip(l:skipdist-l:distancetobeginning, s:left)
        end
    end
endfunction

" ====[ Fixed Skip Mode ]====
function! s:FixedForward()
    let l:line = s:Line(s:current)
    let l:skipdist = s:Scale(strlen(l:line))
    let l:distancetoend = s:DistanceTo(s:EndOf(l:line))

    if l:skipdist <= l:distancetoend
        call s:Skip(l:skipdist, s:right)
    else
        if g:vimskip_wraptocenter
            call s:Wrap("tocenterfromend")
        else
            call s:Wrap("tobeginning")
        end
        call s:Skip(l:skipdist - l:distancetoend, s:right)
    end
endfunction

function! s:FixedBackward()
    let l:line = s:Line(s:current)
    let l:distancetobeginning = s:DistanceTo(s:BeginningOf(l:line))
    let l:skipdist = s:Scale(strlen(l:line))

    if l:skipdist <= l:distancetobeginning
        call s:Skip(l:skipdist, s:left)
    else
        call s:Wrap("toend")
        call s:Skip(l:skipdist - l:distancetobeginning, s:left)
    end
endfunction

" ====[ Vertical Mode ]====
function! s:NormalUp()
    let l:winline = winline()
    if line('.') - l:winline
        let l:dist = l:winline - &scrolloff - 1
    else
        let l:dist = l:winline - 1
    end

    if l:dist
        call s:Skip(s:Scale(l:dist), s:up)
    else
        if g:vimskip_wraptomiddleline
            call s:Wrap("tomiddle")
        else
            call s:Wrap("tobottom")
        end
    end
endfunction

function! s:NormalDown()
    let l:windist = winheight(0) - winline()
    let l:lastlinedist = line('$') - line('.')
    if l:windist >= l:lastlinedist
        let l:dist = l:lastlinedist
    else
        let l:dist = l:windist - &scrolloff
    end

    if l:dist
        call s:Skip(s:Scale(l:dist), s:down)
    else
        if g:vimskip_wraptomiddleline
            call s:Wrap("tomiddle")
        else
            call s:Wrap("totop")
        end
    end
endfunction

" ====[ Dynamic Option Changing ]====
function! s:IncreaseMultiplier()
    let s:factor += 0.05
    echo "vim-skip multiplier is now: ".string(s:factor)
endfunction

function! s:DecreaseMultiplier()
    let s:factor -= 0.05
    echo "vim-skip multiplier is now: ".string(s:factor)
endfunction

function! s:VSMultiplier(value)
    let s:factor = str2float(a:value)
    echo "vim-skip multiplier is now: ".string(s:factor)
endfunction

function! s:ToggleVertical()
    if s:vertmode
        call s:SetMaps(s:switchmode)
        echo "Now skipping horizontally"
        let s:vertmode = 0
    else
        silent! execute 'nmap '.g:vimskip_mapforwardskip.' <Plug>(SkipNORMALDown)'
        silent! execute 'nmap '.g:vimskip_mapforwardskip.' <Plug>(SkipNORMALUp)'
        echo "Now skipping vertically"
        let s:vertmode = 1
    end
endfunction

function! s:SetMaps(...)
    if a:0
        if !hasmapto('<Plug>(Skip'.toupper(a:1).'Forward)')
        \ && empty(maparg(g:vimskip_mapforwardskip, 'n'))
            silent! execute 'nmap '.g:vimskip_mapforwardskip.' <Plug>(Skip'.toupper(a:1).'Forward)'
        end

        if !hasmapto('<Plug>(Skip'.toupper(a:1).'Backward)')
        \ && empty(maparg(g:vimskip_mapbackwardskip, 'n'))
            silent! execute 'nmap '.g:vimskip_mapbackwardskip.' <Plug>(Skip'.toupper(a:1).'Backward)'
        end
    else
        if s:switchmode == "normal"
            s:switchmode = "split"
            echo "Now in split mode"
        elseif s:switchmode == "split"
            s:switchmode = "anti"
            echo "Now in anti mode"
        elseif s:switchmode == "anti"
            s:switchmode = "fixed"
            echo "Now in fixed mode"
        elseif s:switchmode == "fixed"
            s:switchmode = "normal"
            echo "Now in normal mode"
        else
            s:switchmode = "normal"
            echo "Now in normal mode"
        end
        call s:SetMaps(s:switchmode)
    end
endfunction

" ====[ Bindings ]====
nnoremap <silent> <Plug>(SkipToCenter)           :<C-u>call <SID>ToCenter('')<CR>
nnoremap <silent> <Plug>(SkipNORMALForward)      :<C-u>call <SID>NormalForward()<CR>
nnoremap <silent> <Plug>(SkipNORMALBackward)     :<C-u>call <SID>NormalBackward()<CR>
nnoremap <silent> <Plug>(SkipANTIForward)        :<C-u>call <SID>AntiForward()<CR>
nnoremap <silent> <Plug>(SkipANTIBackward)       :<C-u>call <SID>AntiBackward()<CR>
nnoremap <silent> <Plug>(SkipSPLITForward)       :<C-u>call <SID>SplitForward()<CR>
nnoremap <silent> <Plug>(SkipSPLITBackward)      :<C-u>call <SID>SplitBackward()<CR>
nnoremap <silent> <Plug>(SkipFIXEDForward)       :<C-u>call <SID>FixedForward()<CR>
nnoremap <silent> <Plug>(SkipFIXEDBackward)      :<C-u>call <SID>FixedBackward()<CR>
nnoremap <silent> <Plug>(SkipNORMALUp)           :<C-u>call <SID>NormalUp()<CR>
nnoremap <silent> <Plug>(SkipNORMALDown)         :<C-u>call <SID>NormalDown()<CR>
nnoremap <silent> <Plug>(SkipSwitchMode)         :<C-u>call <SID>SetMaps()<CR>
nnoremap <silent> <Plug>(SkipToggleVertical)     :<C-u>call <SID>ToggleVertical()<CR>
nnoremap <silent> <Plug>(SkipIncreaseMultiplier) :<C-u>call <SID>IncreaseMultiplier()<CR>
nnoremap <silent> <Plug>(SkipDecreaseMultiplier) :<C-u>call <SID>DecreaseMultiplier()<CR>

command! -nargs=1 VSMultiplier call s:VSMultiplier(<f-args>)

if !g:vimskip_disable_default_maps
    if !hasmapto('<Plug>(SkipToCenter)')
        silent! execute 'nmap '.g:vimskip_maptocenter.' <Plug>(SkipToCenter)'
    end
    call s:SetMaps(g:vimskip_mode)
end

