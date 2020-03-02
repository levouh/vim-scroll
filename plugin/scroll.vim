" --- Verification

    if exists('g:_loaded_scroll') || v:version < 802 || has('gui_running')
        finish
    endif

    let g:_loaded_scroll = 1

" --- Options

    let g:scroll_down_key = get(g:, 'scroll_down_key', 'j')
    let g:scroll_up_key = get(g:, 'scroll_up_key', 'k')

    if !exists('g:scroll_stop_keys')
        let g:scroll_stop_keys = [
                               \ "j",
                               \ "k",
                               \ "<Esc>"
                               \ ]
    endif

" --- Variables

    " The timing period over which to perform the scroll
    let g:_scroll_interval = 1000.0 / 60

    " The resistant forces that change throughout the scrolling process
    let g:_scroll_friction = 80.0
    let g:_scroll_drag = 2.0

    " The state of the system at any given time
    let g:_scroll_state = {
                        \ "impulse": 0.0,
                        \ "velocity": 0.0,
                        \ "delta": 0.0,
                        \ "lazyredraw": &lazyredraw,
                        \ "relativenumber": &relativenumber,
                        \ "is_visual": 0,
                        \ }

    " Saved mappings from before we setup the 'stop keys'
    let g:_scroll_saved_mappings = {}

" --- Commands

