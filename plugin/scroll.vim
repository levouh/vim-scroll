" Verification {{{1

    if exists('g:_loaded_scroll') || v:version < 802 || &cp
        finish
    endif

    let g:_loaded_scroll = 1

" Options {{{1

    let g:scroll_down_key = get(g:, 'scroll_down_key', 'j')
    let g:scroll_up_key = get(g:, 'scroll_up_key', 'k')
    let g:scroll_stop_key = get(g:, 'scroll_stop_key', [])
    let g:scroll_opposite_behavior = get(g:, 'scroll_opposite_behavior', 1)

" Variables {{{1

    " The timing period over which to perform the scroll
    let g:_scroll_interval = 1000.0 / 60

    " The resistant forces that change throughout the scrolling process
    let g:_scroll_friction = 80.0
    let g:_scroll_air_drag = 2.0

    " The state of the system at any given time
    let g:_scroll_state = {
        \ "impulse": 0.0,
        \ "velocity": 0.0,
        \ "delta": 0.0,
        \ "is_scrolling": 0,
    \ }

" Mappings {{{1

    let s:var_type = type(g:scroll_stop_key)

    if s:var_type != v:t_none
        if s:var_type == v:t_list
            for map_key in g:scroll_stop_key
                let s:map_rhs = map_key .. ' g:_scroll_state.is_scrolling ? scroll#scroll_exit() : "' .. map_key .. '"'
                exe 'noremap <expr> ' .. s:map_rhs
            endfor
        elseif s:var_type == v:t_string
            let s:map_rhs = g:scroll_stop_key .. ' g:_scroll_state.is_scrolling ? scroll#scroll_exit() : "' .. g:scroll_stop_key .. '"'
            exe 'noremap <expr> ' .. s:map_rhs
        endif
    endif

" Commands {{{1

    command! -nargs=1 ScrollUp call scroll#scroll(<args>, 0, 0)
    command! -nargs=1 ScrollDown call scroll#scroll(<args>, 0, 1)
    command! -nargs=1 VScrollUp call scroll#scroll(<args>, 1, 0)
    command! -nargs=1 VScrollDown call scroll#scroll(<args>, 1, 1)
