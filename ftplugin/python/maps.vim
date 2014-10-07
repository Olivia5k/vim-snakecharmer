command! -buffer -nargs=0 SnakeArgs       :call SnakeArgs()
command! -buffer -nargs=0 SnakeMockArgs   :call SnakeMockArgs()
command! -buffer -nargs=0 SnakeTest       :call snakecharmer#pytest#Sharpshooter()
command! -buffer -nargs=0 SnakeTestAll    :call snakecharmer#pytest#Scattershooter()
command! -buffer -nargs=0 SnakeTestCreate :call snakecharmer#pytest#Sniper()
command! -buffer -nargs=0 SnakeTestNext   :call snakecharmer#pytest#Medic(1)
command! -buffer -nargs=0 SnakeTestPrev   :call snakecharmer#pytest#Medic(-1)

map <buffer><silent> <Plug>SnakeArgs       :SnakeArgs<cr>
map <buffer><silent> <Plug>SnakeMockArgs   :SnakeMockArgs<cr>
map <buffer><silent> <Plug>SnakeTest       :SnakeTest<cr>
map <buffer><silent> <Plug>SnakeTestAll    :SnakeTestAll<cr>
map <buffer><silent> <Plug>SnakeTestCreate :SnakeTestCreate<cr>
map <buffer><silent> <Plug>SnakeTestNext   :SnakeTestNext<cr>
map <buffer><silent> <Plug>SnakeTestPrev   :SnakeTestPrev<cr>

if !exists('g:snakecharmer_disable_maps')
  nmap <buffer> <cr>       <Plug>SnakeTest
  nmap <buffer> <c-s><c-s> <Plug>SnakeTest

  nmap <buffer> <c-s>a <Plug>SnakeArgs
  nmap <buffer> <c-s>m <Plug>SnakeMockArgs
  nmap <buffer> <c-s>d <Plug>SnakeTestAll
  nmap <buffer> <c-s>c <Plug>SnakeTestCreate
  nmap <buffer> <c-s>j <Plug>SnakeTestNext
  nmap <buffer> <c-s>k <Plug>SnakeTestNext
endif
