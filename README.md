## vim-scroll

_Physics based scrolling._

### Note

I have no idea what I am doing, so if you find a problem with this plugin please let me know.

### Support

8.2.227+

### Installation

```
Plug 'levouh/vim-scroll'
```

### Setup

This plugin comes with no default mappings, but I'd recomend something like this:

```
nnoremap <silent> <C-d> :ScrollUp 125<CR>
nnoremap <silent> <C-u> :ScrollDown 125<CR>
xnoremap <silent> <C-d> :<C-u>VScrollUp 125<CR>
xnoremap <silent> <C-u> :<C-u>VScrollDown 125<CR>
```

where the argument is how strong you want the "flick" to be. The `<C-u>` prefix is necessary for visual mode mappings, and note the different commands.

### Configuration

The default behavior of this plugin is to scroll the cursor, but if you'd like it to scroll the screen instead:

```
let g:scroll_down_key = '<C-e>'
let g:scroll_up_key = '<C-y>'
```

By default, this plugin will scroll in the opposite direction if you are using `ScrollDown` and the issue a `ScrollUp` for instance.
If you want scrolling in the opposite direction to _stop_ the scrolling instead, you can set:

```
let g:scroll_opposite_behavior = 0
```

Because scrolling uses timers, the scroll you have setup might end up scrolling farther than you want.
You can set keys that will stop the scrolling like so:

```
let g:scroll_stop_key = [
                        \ "j",
                        \ "k"
                        \ ]
```

You can also just define a single key:

```
let g:scroll_stop_key = "\<Esc>"
```

### Versus comfortable-motion.vim

- Supports scrolling with visual selection.
- Supports configurable continued/stopped scrolling when scrolling in the opposite direction.
- Stops scrolling when the top or bottom of the buffer is hit.
- Controls velocity so that is is rational.
- Stop scrolling when window focus is changed.
- User can defined additional mappings to stop the scrolling while it is happening..

### Mentions

Most of this plugin is taken from [comfortable-motion.vim](https://github.com/yuttie/comfortable-motion.vim)
