" --- Public Functions

    " Move the cursor down the screen in a smooth fashion.
    function! scroll#scroll(impulse, is_visual)
        " 'Stack up' multiple calls to scrolling, but prevent it from being infinite.
        if a:impulse > 0
            " Scrolling down.
            if g:_scroll_state.impulse < a:impulse
                let g:_scroll_state.impulse += a:impulse
            endif
        else
            " Scrolling up.
            if g:_scroll_state.impulse > a:impulse
                let g:_scroll_state.impulse += a:impulse
            endif
        endif

        if a:is_visual
            let g:_scroll_state.is_visual = 1
            if a:impulse > 0
                " Scrolling down.
                call setpos(".", getpos("'>"))
            else
                " Scrolling up.
                call setpos(".", getpos("'<"))
            endif

            " Don't redraw during macros.
            if &lazyredraw
                let g:_scroll_state.lazyredraw = 1
            else
                let g:_scroll_state.lazyredraw = 0
            endif

            " Speed things up by not using relativenumber.
            if &relativenumber
                let g:_scroll_state.relativenumber = 1
            else
                let g:_scroll_state.relativenumber = 0
            endif
        endif

        if !empty(g:scroll_stop_keys) && empty(g:_scroll_saved_mappings)
            " Save mappings for keys used to stop the scrolling.
            let g:_scroll_saved_mappings = s:scroll_save_mappings(g:scroll_stop_keys, "n", 1)

            " Map requested keys to stop the scrolling.
            for val in g:scroll_stop_keys
                exe "nnoremap <silent> " . val . " :call s:scroll_flick(-1, 1)<CR>"
            endfor
        endif

        if !exists("g:_scroll_timer_id")
            " There is no thread, start one.
            let l:interval = float2nr(round(g:_scroll_interval))

            " Infinitely call the callback, rely on it stopping itself when velocity reaches zero.
            let g:_scroll_timer_id = timer_start(l:interval, function("s:scroll_flick"), {"repeat": -1})
        endif

        " Alias to global value
        let l:st = g:_scroll_state

        " Stop if velocity and impulse are opposite directions.
        if (l:st.velocity > 0 && a:impulse < 0) || (l:st.velocity < 0 && a:impulse > 0)
            let g:_scroll_state.impulse -= l:st.velocity * 4 / 3
        else
            let g:_scroll_state.impulse = a:impulse - l:st.velocity
        endif
    endfunction


" --- Private Functions

    " Perform the screen or cursor scrolling.
    function! s:scroll_flick(timer_id, ...)
        " Local copy of global variable.
        let l:st = g:_scroll_state

        if a:0
            " Mappings to stop the scrolling was issued.
            call s:scroll_exit()

            return
        endif

        " Only continue if the velocity is greater than 1, otherwise stop the timer and exit.
        if abs(l:st.velocity) >= 1 || l:st.impulse != 0
            " Determine the current cursor position.
            let l:cur_pos = line(".")

            " Gather data to exit if we are at the top or bottom of the screen.
            if l:st.impulse > 0
                " Scroll down.
                let l:end_of_buffer = line("$")
                let l:vis_block = "w$"
            elseif l:st.impulse < 0
                " Scroll up.
                let l:end_of_buffer = 1
                let l:vis_block = "w0"
            else
                " Special case.
                let l:end_of_buffer = 0
            endif

            if l:cur_pos == l:end_of_buffer
                " We are already at the top and scrolling up, or already at the bottom
                " and srolling down.
                call s:scroll_exit()

                " Exit as there is nothing left to do.
                return
            endif

            " Convert milliseconds to seconds.
            let l:dt = g:_scroll_interval / 1000.0

            " Compute resistance forces.
            let l:vel_sign = l:st.velocity == 0
                           \ ? 0
                           \ : l:st.velocity / abs(l:st.velocity)

            " The mass is 1.
            let l:friction = -l:vel_sign * g:_qsc_friction * 1
            let l:air_drag = -l:st.velocity * g:_qsc_air_drag
            let l:additional_force = l:friction + l:air_drag

            " Update the state.
            let l:st.delta += l:st.velocity * l:dt
            let l:st.velocity += l:st.impulse + (abs(l:additional_force * l:dt) > abs(l:st.velocity) ? -l:st.velocity : l:additional_force * l:dt)
            let l:st.impulse = 0

            " Perform the scrolling.
            let l:int_delta = float2nr(l:st.delta >= 0 ? floor(l:st.delta) : ceil(l:st.delta))
            let l:st.delta -= l:int_delta

            if l:st.is_visual
                exe "normal! \<ESC>"
                normal! gv
            endif

            if l:int_delta > 0
                exe "normal! " . string(abs(l:int_delta)) . g:qsc_down_key
            elseif l:int_delta < 0
                exe "normal! " . string(abs(l:int_delta)) . g:qcs_up_key
            endif

            redraw
        else
            " Stop scrolling.
            call s:scroll_exit()
        endif
    endfunction

    " Stop the scrolling animation.
    function! s:scroll_exit()
        " Stop scrolling by terminating the infinite callback to this function.
        call timer_stop(g:_scroll_timer_id)

        " Free up for future calls.
        unlet g:_scroll_timer_id

        " Make sure the state is reset if we are exiting.
        let g:_scroll_state.velocity = 0.0
        let g:_scroll_state.impulse = 0.0
        let g:_scroll_state.delta = 0.0
        let g:_scroll_state.is_visual = 0

        " Restore redraw state.
        if !g:_scroll_state.lazyredraw
            set nolazyredraw
        endif

        " Restore relativenumber setting.
        if g:_scroll_state.relativenumber
            set relativenumber
        endif

        if !empty(g:_scroll_saved_mappings)
            call s:scroll_restore_mappings(g:_scroll_saved_mappings)
            let g:_scroll_saved_mappings = {}
        endif
    endfunction

    " Save a mapping that we can then restore later to allow exiting while scrolling.
    function! s:scroll_save_mappings(keys, mode, global)
        let l:mappings = {}

        if a:global
            for l:key in a:keys
                let l:buf_local_map = maparg(l:key, a:mode, 0, 1)

                silent! exe a:mode . "unmap <buffer> " . l:key

                let l:map_info = maparg(l:key, a:mode, 0, 1)
                let l:mappings[l:key] = !empty(l:map_info) ? l:map_info :
                                      \ {
                                      \ "unmapped" : 1,
                                      \ "buffer"   : 0,
                                      \ "lhs"      : l:key,
                                      \ "mode"     : a:mode,
                                      \ }

                call s:scroll_restore_mappings({l:key : l:buf_local_map})
            endfor

        else
            for l:key in a:keys
                let l:map_info = maparg(l:key, a:mode, 0, 1)
                let l:mappings[l:key] = !empty(l:map_info) ? l:map_info :
                                      \ {
                                      \ "unmapped" : 1,
                                      \ "buffer"   : 1,
                                      \ "lhs"      : l:key,
                                      \ "mode"     : a:mode,
                                      \ }
            endfor
        endif

        return l:mappings
    endfunction

    " Restore a set of saved mappings
    function! s:scroll_restore_mappings(mappings)
        for mapping in values(a:mappings)
            if !has_key(mapping, "unmapped") && !empty(mapping)
                exe mapping.mode
                    \ . (mapping.noremap ? "noremap   " : "map ")
                    \ . (mapping.buffer  ? " <buffer> " : "")
                    \ . (mapping.expr    ? " <expr>   " : "")
                    \ . (mapping.nowait  ? " <nowait> " : "")
                    \ . (mapping.silent  ? " <silent> " : "")
                    \ .  mapping.lhs
                    \ . " "
                    \ . substitute(mapping.rhs, "<SID>", "<SNR>" . mapping.sid . "_", "g")

            elseif has_key(mapping, "unmapped")
                silent! exe mapping.mode . "unmap "
                                  \ .(mapping.buffer ? " <buffer> " : "")
                                  \ . mapping.lhs
            endif
        endfor
    endfunction
