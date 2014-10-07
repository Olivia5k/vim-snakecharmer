command! -buffer -nargs=0 SnakeArgs            :call SnakeArgs()
command! -buffer -nargs=0 SnakeMockArgs        :call SnakeMockArgs()
command! -buffer -nargs=0 SnakeTest            :call snakecharmer#pytest#Single()
command! -buffer -nargs=0 SnakeTestCreate      :call snakecharmer#pytest#Sniper()
command! -buffer -nargs=0 SnakeTestNext        :call snakecharmer#pytest#Browse(1)
command! -buffer -nargs=0 SnakeTestPrev        :call snakecharmer#pytest#Browse(-1)
command! -buffer -nargs=0 SnakeTestUnit        :call snakecharmer#pytest#Unit()
command! -buffer -nargs=0 SnakeTestIntegration :call snakecharmer#pytest#Integration()
command! -buffer -nargs=0 SnakeTestAll         :call snakecharmer#pytest#All()

command! -buffer -nargs=* -complete=customlist,PytestComplete Switch :call snakecharmer#pytest#Switch(<f-args>)
command! -buffer -nargs=* -complete=customlist,PytestComplete PS :call snakecharmer#pytest#Switch(<f-args>)

map <buffer><silent> <Plug>SnakeArgs             :SnakeArgs<cr>
map <buffer><silent> <Plug>SnakeMockArgs         :SnakeMockArgs<cr>
map <buffer><silent> <Plug>SnakeTest             :SnakeTest<cr>
map <buffer><silent> <Plug>SnakeTestUnit         :SnakeTestUnit<cr>
map <buffer><silent> <Plug>SnakeTestCreate       :SnakeTestCreate<cr>
map <buffer><silent> <Plug>SnakeTestNext         :SnakeTestNext<cr>
map <buffer><silent> <Plug>SnakeTestPrev         :SnakeTestPrev<cr>
map <buffer><silent> <Plug>SnakeTestIntegration  :SnakeTestIntegration<cr>
map <buffer><silent> <Plug>SnakeTestAll          :SnakeTestAll<cr>

if !exists('g:snakecharmer_disable_maps')
  nmap <buffer> <cr>       <Plug>SnakeTest
  nmap <buffer> <c-s><c-s> <Plug>SnakeTest

  nmap <buffer> <c-s>a <Plug>SnakeArgs
  nmap <buffer> <c-s>m <Plug>SnakeMockArgs
  nmap <buffer> <c-s>c <Plug>SnakeTestCreate
  nmap <buffer> <c-s>j <Plug>SnakeTestNext
  nmap <buffer> <c-s>k <Plug>SnakeTestPrev
  nmap <buffer> <c-s>u <Plug>SnakeTestUnit
  nmap <buffer> <c-s>i <Plug>SnakeTestIntegration
  nmap <buffer> <c-s>t <Plug>SnakeTestAll
endif
