" py.test switches {{{

" Note: These are all to be used with util/t found in this same dotfiles repo

function! snakecharmer#pytest#PytestSwitch(...)
  let print = a:0 > 2 ? a:3 : 1
  let runit = a:0 > 3 ? a:4 : 1
  let dir = getcwd() . '/.git/sharpshooter'
  let target = a:0 ? a:1 : ""
  let file = dir . '/' . target

  if print
    echohl PreProc | echon 'Pytest' | echohl None | echon ": "
  endif

  if !isdirectory(dir)
    call mkdir(dir)
  endif

  " No arguments, print current
  if target == ""
    if print
      echon snakecharmer#pytest#PytestCurrent()
    endif
    return
  endif

  if filereadable(file) && len(a:000) == 1
    " File exists and no arg was passed; kill the switch
    call delete(file)
    if print
      echohl Constant
      echon 'Disabled '
      echon target
    endif
  else
    " New switch! Write the rest of the args list into it
    call writefile(a:000[1:1], file, "b")

    if print
      echohl String
      echon 'Enabled ' . target
      if a:0 > 1
        echon  ' as ' . a:2
      endif
    endif
  endif

  if print
    echohl None
  endif

  " Retrigger the tests
  if runit == 1
    call snakecharmer#pytest#PytestRun()
  endif
endfunction

function! snakecharmer#pytest#PytestRun()
  let fn = getcwd() . '/.git/sharpshooter.fifo'
  call writefile(['bang bang'], fn)
  doau BufWritePost
endfunction

function! snakecharmer#pytest#PytestCurrent()
  let dir = getcwd() . '/.git/sharpshooter'
  if !isdirectory(dir)
    return ''
  endif
  let list = split(globpath(dir, '**/*'), '\n')
  return join(map(list, 'fnamemodify(v:val, ":t")'), ", ")
endfunction

let g:pytest_cache = []
function! snakecharmer#pytest#PytestComplete(a,l,p)
  let pt = getcwd() . '/bin/py.test'
  if !filereadable(pt)
    return []
  endif

  if g:pytest_cache != []
    let args = g:pytest_cache
  else
    let help = split(system(pt .' --help'), '\n')
    let help = filter(help, 'v:val =~ "^  -"')
    " TODO: Args with multiple forms
    let help = map(help, 'substitute(v:val, "^  --\\?\\([-a-z]*\\).*", "\\1", "")')
    let args = sort(help)
    let g:pytest_cache = args
  endif

  return filter(copy(args), 'v:val =~ "^'.a:a.'"')
endfunction

command! -nargs=* -complete=customlist,PytestComplete PytestSwitch :call snakecharmer#pytest#PytestSwitch(<f-args>)
command! -nargs=* -complete=customlist,PytestComplete PS :call snakecharmer#pytest#PytestSwitch(<f-args>)

if exists('*airline#extensions#pytest#get_current')
  let g:airline_section_y = '%= %{airline#util#wrap(airline#extensions#pytest#get_current(),0)}'
endif

" }}}
" Sharpshooter {{{

" Run one test and one test only
function! snakecharmer#pytest#Sharpshooter() " {{{
  " TODO: Execution from outside of test files
  " TODO: Running all tests

  " Save the file so that we are sure it is up to date.
  silent update

  let fn = expand('%')
  if fn =~ 'test/.*'
    let pos = snakecharmer#pytest#SnakeskinParse(fn).position()

    " Check if the current function follows the default py.test pattern.
    if pos != [] && pos[0] =~ '^Test' && pos[1] =~ '^test_'
      " If it does, store it as the only test to execute...
      call snakecharmer#pytest#PytestSwitch('k', join(pos, ' and '), 0, 0)
      call snakecharmer#pytest#PytestSwitch('file', fn, 0, 1)

      " ...and highlight the name in the buffer.
      call snakecharmer#pytest#HiInterestingWord(1, pos[1])
      return
    endif
  endif

  " If we're not setting a new test, just execute the last set one
  call snakecharmer#pytest#PytestRun()
endfunction " }}}

" Run all tests, disabling anything set by snakecharmer#pytest#Sharpshooter().
function! snakecharmer#pytest#Scattershooter() " {{{
  call clearmatches()
  let dir = getcwd() . '/.git/sharpshooter'
  for fn in [dir.'/k', dir.'/file']
    if filereadable(fn)
      call delete(fn)
    endif
  endfor
  call snakecharmer#pytest#PytestRun()
endfunction " }}}

" Navigate to a test, creating a stub test class if it does not exist.
function! snakecharmer#pytest#Sniper() " {{{
  " TODO: Fix case of util functions outside of classes
  " TODO: Fix case when not under method
  let fn = expand('%')
  if fn =~ 'test/'
    return
  endif

  " module/(file).py
  let pos = snakecharmer#pytest#SnakeskinParse(fn).position()

  if len(pos) == 2
    " Class and method
    let first = s:camelize(pos[0])
    let s = substitute(substitute(pos[1], '_\+', '_', 'g'), '_$', '', '')
    let second = s:camelize(s)

    let targets = [first . second, first]
  elseif len(pos) == 1
    " Just one class or method
    let first = s:camelize(pos[0])
    let targets = [first]
  endif

  only
  execute "AV"

  for target in targets
    let clspos = search("class Test".target."(.*:$", 'cw')
    if clspos != 0
      break
    endif
  endfor

  if clspos == 0
    " Class not found. Append it to the end of the file, or below the closest
    " related test class!
    let lines = ['class Test'.targets[0].'(object):', '    pass']

    " Go to end of file and search upward for Test<Class>
    normal G
    let otherpos = search("class Test".pos[0], 'cb')
    let nextpos = search("^class Test", 'W')

    if otherpos != 0 && nextpos != 0
      " There are already test for the class, and this is not the last one;
      " insert the new class after the last test of this class.
      let lnr = nextpos - 1
      let add = 1

      " Also, check if the previous test class inherited from something else.
      " If that was the case, snatch that!
      let match = matchlist(getline(search('^class', 'bn')), '.*(\(.\w\+\))')
      if match[1] != ''
        let lines[0] = substitute(lines[0], '(.\w\+)', '('.match[1].')', '')
      endif

      " Finally, set what is to be appended
      let lines = lines + ['', '']
    else
      " There are no test for this class, or it's the last group of tests.
      " Append at the end of the file..
      let lnr = line('$')
      let lines = ['', ''] + lines
      let add = 5
    endif

    call append(lnr, lines)

    " Land on the last "pass"
    let pos = getpos('.')
    let pos[1] = lnr + add
    let pos[2] = 5
    call setpos('.', pos)
  endif

  normal zt
  normal zM
  normal zA
endfunction " }}}

function! snakecharmer#pytest#Medic(shift) " {{{
  echohl Statement
  echon 'Medic'
  echohl None
  echon ': '

  let file = '.git/sharpshooter.log'

  if !filereadable(file)
    echohl Identifier
    echon 'No sharpshooter log file.'
    echohl None
    return
  endif

  let index = 0
  let lines = filter(readfile(file), 'v:val =~ "^[^. ]"')

  if len(lines) == 0
    echohl Identifier
    echon 'No errors'
    echohl None
    return
  endif

  let shift = lines[-1]
  if shift =~ '\d'
    let lines = lines[0:-2]
    let shift += a:shift
    let index = shift % len(lines)
  endif

  let line = lines[index]
  let spl = split(line, '::')
  silent exe 'edit' split(spl[0], ' ')[1]
  call search(spl[3] . '(')
  call writefile(lines + [index], file)

  normal zMzAzz

  echohl Number
  echon index(lines, line) + 1
  echon '/'
  echon len(lines)
  echohl None
  echon ' - '
  echohl Function
  echon spl[0] . '.' . spl[1]
  echohl None
endfunction " }}}

function! s:camelize(s)
  if a:s =~ '_'
    " Move from snake_case to CamelCase.
    " http://vim.wikia.com/wiki/Converting_variables_to_or_from_camel_case
    let pat = '\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)'
  else
    " Just capitalize the first letter
    let pat = '^\(.\)\(.*\)'
  endif
  return substitute(a:s, pat , '\u\1\2', 'g')
endfunction

" }}}
