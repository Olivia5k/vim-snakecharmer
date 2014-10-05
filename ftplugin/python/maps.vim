command! -nargs=0 SnakeArgs :call SnakeArgs()

map <Plug>SnakeArgs :SnakeArgs<cr>

if !exists('g:snakecharmer_disable_maps')
  nmap <silent> <c-s>a <Plug>SnakeArgs
endif
