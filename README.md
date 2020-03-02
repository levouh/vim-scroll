## vim-scroll

_Physics based scrolling._

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

You can also stop the scrolling in by adding a key to this list, or overriding it all together:

```
let g:scroll_stop_keys = [
                       \ "j",
                       \ "k",
                       \ "<Esc>"
                       \ ]
```

which for now will try to save your current mappings for those keys, but this may be removed in the future.

### Mentions

Most of this plugin is taken from [comfortable-motion.vim](https://github.com/yuttie/comfortable-motion.vim)

### TODO

- Save mappings for visual mode as well.
