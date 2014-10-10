" ftplugin/python/maps.vim
" Author:       Lowe Thiderman <lowe.thiderman@gmail.com>

if exists('g:loaded_snakecharmer_maps') || &cp || v:version < 700
  finish
endif
let g:loaded_snakecharmer_maps = 1

let s:cpo_save = &cpo
set cpo&vim

command! -buffer -nargs=0 SnakeArgs            :call SnakeArgs()
command! -buffer -nargs=0 SnakeMockArgs        :call SnakeMockArgs()
command! -buffer -nargs=0 SnakeTest            :call snakecharmer#pytest#Single()
command! -buffer -nargs=0 SnakeTestCreate      :call snakecharmer#pytest#Sniper()
command! -buffer -nargs=0 SnakeTestNext        :call snakecharmer#pytest#Browse(1)
command! -buffer -nargs=0 SnakeTestPrev        :call snakecharmer#pytest#Browse(-1)
command! -buffer -nargs=0 SnakeTestUnit        :call snakecharmer#pytest#Unit()
command! -buffer -nargs=0 SnakeTestIntegration :call snakecharmer#pytest#Integration()
command! -buffer -nargs=0 SnakeTestAll         :call snakecharmer#pytest#All()

command! -buffer -nargs=* -complete=customlist,snakecharmer#pytest#PytestComplete
      \ SnakeTestSwitch :call snakecharmer#pytest#Switch(<f-args>)

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
  nnoremap <buffer> <cr> :call snakecharmer#pytest#Single()<cr>

  nmap <buffer> <c-s>d <Plug>SnakeTest

  nmap <buffer> <c-s>a <Plug>SnakeArgs
  nmap <buffer> <c-s>m <Plug>SnakeMockArgs
  nmap <buffer> <c-s>c <Plug>SnakeTestCreate
  nmap <buffer> <c-s>j <Plug>SnakeTestNext
  nmap <buffer> <c-s>k <Plug>SnakeTestPrev
  nmap <buffer> <c-s>u <Plug>SnakeTestUnit
  nmap <buffer> <c-s>i <Plug>SnakeTestIntegration
  nmap <buffer> <c-s>t <Plug>SnakeTestAll
endif

let &cpo = s:cpo_save
" vim:set sw=2 sts=2:
