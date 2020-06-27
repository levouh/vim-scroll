" Public functions {{{1

    fu! scroll#scroll(impulse, is_visual, is_down) " {{{2
        " Move the cursor down the screen in a smooth fashion
        "
        " Handle improper arguments being passed by ensuring the impulse is
        " always a positive number
        let impulse = a:impulse < 0 ? a:impulse * -1 : a:impulse

        " Alias to global value
        let st = g:_scroll_state

        if a:is_down
            " Scrolling down
            let impulse = impulse * -1

            if st.impulse > impulse
                " 'Stack up' multiple calls to scrolling, but prevent it from being infinite
                let st.impulse += impulse
            endif
        else
            " Scrolling up.
            if st.impulse < impulse
                let st.impulse += impulse
            endif
        endif

        if a:is_visual
            normal! gv
        endif

        if !exists("g:_scroll_timer_id")
            " Try to speed things up by changing options
            let st.lazyredraw = &lazyredraw
            let st.relativenumber = &relativenumber
            let st.cursorline = &cursorline

            set lazyredraw
            set norelativenumber
            set nocursorline

            let st.is_scrolling = 1

            let g:_scroll_winid = win_getid()

            " There is no thread, start one
            let interval = float2nr(round(g:_scroll_interval))

            " Infinitely call the callback, rely on it stopping itself when velocity reaches zero
            let g:_scroll_timer_id = timer_start(interval, function("s:scroll_flick"), {"repeat": -1})
        endif

        " Stop if velocity and impulse are opposite directions.
        if (st.velocity > 0 && impulse < 0) || (st.velocity < 0 && impulse > 0)
            if g:scroll_opposite_behavior == 1
                let st.impulse -= st.velocity * 4 / 3
            else
                call scroll#scroll_exit()
            endif
        else
            let st.impulse = impulse - st.velocity
        endif
    endfu

    fu! scroll#scroll_exit() " {{{2
        " Alias to global value
        let st = g:_scroll_state

        " Stop the scrolling animation.
        let st.is_scrolling = 0

        " Stop scrolling by terminating the infinite callback to this function.
        call timer_stop(g:_scroll_timer_id)

        unlet g:_scroll_winid

        " Free up for future calls.
        unlet g:_scroll_timer_id

        " Make sure the state is reset if we are exiting.
        let st.velocity = 0.0
        let st.impulse = 0.0
        let st.delta = 0.0

        " Restore settings
        if !st.lazyredraw
            set nolazyredraw
        endif

        if st.relativenumber
            set relativenumber
        endif

        if st.cursorline
            set cursorline
        endif
    endfu

" Private functions {{{1

    fu! s:scroll_flick(timer_id) " {{{2
        " Perform the screen or cursor scrolling.
        if win_getid() != g:_scroll_winid
            call scroll#scroll_exit()

            return
        endif

        " Local copy of global variable.
        let st = g:_scroll_state

        " Only continue if the velocity is greater than 1, otherwise stop the timer and exit.
        if abs(st.velocity) >= 1 || st.impulse != 0
            " Determine the current cursor position.
            let cur_pos = line(".")

            " Gather data to exit if we are at the top or bottom of the screen.
            if st.impulse > 0
                " Scroll down.
                let end_of_buffer = line("$")
            elseif st.impulse < 0
                " Scroll up.
                let end_of_buffer = 1
            else
                " Special case.
                let end_of_buffer = 0
            endif

            if cur_pos == end_of_buffer
                " We are already at the top and scrolling up, or already at the bottom
                " and srolling down.
                call scroll#scroll_exit()

                " Exit as there is nothing left to do.
                return
            endif

            " Convert milliseconds to seconds.
            let dt = g:_scroll_interval / 1000.0

            " Compute resistance forces.
            let vel_sign = st.velocity == 0
                           \ ? 0
                           \ : st.velocity / abs(st.velocity)

            " The mass is 1.
            let friction = -vel_sign * g:_scroll_friction * 1
            let air_drag = -st.velocity * g:_scroll_air_drag
            let additional_force = friction + air_drag

            " Update the state.
            let st.delta += st.velocity * dt
            let st.velocity += st.impulse + (abs(additional_force * dt) > abs(st.velocity) ? -st.velocity : additional_force * dt)
            let st.impulse = 0

            " Perform the scrolling.
            let int_delta = float2nr(st.delta >= 0 ? floor(st.delta) : ceil(st.delta))
            let st.delta -= int_delta

            if int_delta > 0
                exe "normal! " .. string(abs(int_delta)) .. g:scroll_down_key
            elseif int_delta < 0
                exe "normal! " .. string(abs(int_delta)) .. g:scroll_up_key
            endif

            redraw
        else
            " Stop scrolling.
            call scroll#scroll_exit()
        endif
    endfu
