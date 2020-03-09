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

        if a:is_visual && !g:_scroll_state.is_visual
            let g:_scroll_state.is_visual = 1

            " Called from a visual mode mapping, setup the selection only once.
            if a:impulse > 0
                " Scrolling down.
                call setpos(".", getpos("'>"))
            else
                " Scrolling up.
                call setpos(".", getpos("'<"))
            endif
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

        if !exists("g:_scroll_timer_id")
            let g:_scroll_winid = win_getid()

            " There is no thread, start one.
            let l:interval = float2nr(round(g:_scroll_interval))

            " Infinitely call the callback, rely on it stopping itself when velocity reaches zero.
            let g:_scroll_timer_id = timer_start(l:interval, function("s:scroll_flick"), {"repeat": -1})
        endif

        " Alias to global value
        let l:st = g:_scroll_state

        " Stop if velocity and impulse are opposite directions.
        if (l:st.velocity > 0 && a:impulse < 0) || (l:st.velocity < 0 && a:impulse > 0)
            if g:scroll_opposite_behavior == 1
                let g:_scroll_state.impulse -= l:st.velocity * 4 / 3
            else
                call s:scroll_exit()
            endif
        else
            let g:_scroll_state.impulse = a:impulse - l:st.velocity
        endif
    endfunction


" --- Private Functions

    " Perform the screen or cursor scrolling.
    function! s:scroll_flick(timer_id)
        if win_getid() != g:_scroll_winid
            call s:scroll_exit()

            return
        endif

        " Local copy of global variable.
        let l:st = g:_scroll_state

        " Only continue if the velocity is greater than 1, otherwise stop the timer and exit.
        if abs(l:st.velocity) >= 1 || l:st.impulse != 0
            " Determine the current cursor position.
            let l:cur_pos = line(".")

            " Gather data to exit if we are at the top or bottom of the screen.
            if l:st.impulse > 0
                " Scroll down.
                let l:end_of_buffer = line("$")
            elseif l:st.impulse < 0
                " Scroll up.
                let l:end_of_buffer = 1
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
            let l:friction = -l:vel_sign * g:_scroll_friction * 1
            let l:air_drag = -l:st.velocity * g:_scroll_air_drag
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
                exe "normal! " . string(abs(l:int_delta)) . g:scroll_down_key
            elseif l:int_delta < 0
                exe "normal! " . string(abs(l:int_delta)) . g:scroll_up_key
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

        unlet g:_scroll_winid

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
    endfunction
