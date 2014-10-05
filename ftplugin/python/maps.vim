command! -nargs=0 SnakeArgs :call SnakeArgs()
command! -nargs=0 SnakeMockArgs :call SnakeMockArgs()

map <Plug>SnakeArgs :SnakeArgs<cr>
map <Plug>SnakeMockArgs :SnakeMockArgs<cr>

if !exists('g:snakecharmer_disable_maps')
  nmap <silent> <c-s>a <Plug>SnakeArgs
  nmap <silent> <c-s>m <Plug>SnakeMockArgs
endif
