command! -buffer -nargs=0 SnakeArgs :call SnakeArgs()
command! -buffer -nargs=0 SnakeMockArgs :call SnakeMockArgs()

map <buffer> <Plug>SnakeArgs :SnakeArgs<cr>
map <buffer> <Plug>SnakeMockArgs :SnakeMockArgs<cr>

if !exists('g:snakecharmer_disable_maps')
  nmap <buffer> <cr> :call Sharpshooter()<cr>
  nmap <buffer> <c-s><c-s> :call Sharpshooter()<cr>

  nmap <buffer> <c-s>a <Plug>SnakeArgs
  nmap <buffer> <c-s>m <Plug>SnakeMockArgs
  nmap <buffer> <c-s>d :call Scattershooter()<cr>
  nmap <buffer> <c-s>s :call Sniper()<cr>
  nmap <buffer> <c-s>j :call Medic(1)<cr>
  nmap <buffer> <c-s>k :call Medic(-1)<cr>
endif
