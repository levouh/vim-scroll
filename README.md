## vim-scroll

_Physics based scrolling._

### Note

I have no idea what I am doing, so if you find a problem with this plugin please let me know.

### Support

_Vim_: 8.2.227  
_OS_: Linux

### Installation

```
Plug 'levouh/vim-scroll'
```

### Setup

This plugin comes with no default mappings, but I'd recomend something like this:

```
nnoremap <silent> <C-d> :call scroll#scroll(150, 0)<CR>
xnoremap <silent> <C-d> :call scroll#scroll(150, 1)<CR>
nnoremap <silent> <C-u> :call scroll#scroll(-150, 0)<CR>
xnoremap <silent> <C-u> :call scroll#scroll(-150, 1)<CR>
```

where the first argument is how strong you want the "flick" to me, and the second argument correlates to whether or not this is a visual mode mapping.

### Configuration

The default behavior of this plugin is to scroll the curson, but if you'd like it to scroll the screen instead:

```
let g:scroll_down_key = '<C-e>'
let g:scroll_up_key = '<C-y>'
```

By default, this plugin will stop the scrolling all together if you scroll in the opposite direction.
If you wish to change this to instead continue scrolling but in the opposite direction, you can set:

```
let g:scroll_opposite_behavior = 1
```

which for now will try to save your current mappings for those keys, but this may be removed in the future.

### Versus comfortable-motion.vim

- Supports scrolling with visual selection.
- Supports configurable continued/stopped scrolling when scrolling in the opposite direction.
- Stops scrolling when the top or bottom of the buffer is hit.
- Controls velocity so that is is rational.
- Stop scrolling when window focus is changed.

### Mentions

Most of this plugin is taken from [comfortable-motion.vim](https://github.com/yuttie/comfortable-motion.vim)
