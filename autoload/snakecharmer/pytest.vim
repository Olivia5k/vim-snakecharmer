let g:snakecharmer_pytest_args_cache = []

function! snakecharmer#pytest#Switch(...) " {{{
  let print = a:0 > 2 ? a:3 : 1
  let runit = a:0 > 3 ? a:4 : 1
  let dir = s:dir('switches/')
  let target = a:0 ? a:1 : ""
  let file = dir . '/' . target

  if print
    echohl PreProc | echon 'SnakeTest' | echohl None | echon ": "
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
    call snakecharmer#pytest#Run()
  endif
endfunction " }}}

function! snakecharmer#pytest#Run() " {{{
  " call snakecharmer#pytest#Start()

  call writefile(['run'], s:dir('fifo'))

  doau BufWritePost
endfunction " }}}

function! snakecharmer#pytest#PytestCurrent() " {{{
  let dir = s:dir()
  if !isdirectory(dir)
    return ''
  endif
  let list = split(globpath(dir, '**/*'), '\n')
  return join(map(list, 'fnamemodify(v:val, ":t")'), ", ")
endfunction " }}}

function! snakecharmer#pytest#PytestComplete(a,l,p) " {{{
  let pt = getcwd() . '/bin/py.test'
  if !filereadable(pt)
    return []
  endif

  if g:snakecharmer_pytest_args_cache != []
    let args = g:snakecharmer_pytest_args_cache
  else
    let help = split(system(pt .' --help'), '\n')
    let help = filter(help, 'v:val =~ "^  -"')
    " TODO: Args with multiple forms
    let help = map(help, 'substitute(v:val, "^  --\\?\\([-a-z]*\\).*", "\\1", "")')
    let args = sort(help)
    let g:snakecharmer_pytest_args_cache = args
  endif

  return filter(copy(args), 'v:val =~ "^'.a:a.'"')
endfunction " }}}

function! snakecharmer#pytest#Single() " {{{
  " Run one test and one test only
  " TODO: Execution from outside of test files

  " Save the file so that we are sure it is up to date.
  silent update

  let fn = expand('%')
  if fn =~ 'test/.*'
    let pos = snakeskin#SnakeskinParse(fn).position()

    " Check if the current function follows the default py.test pattern.
    if pos != [] && pos[0] =~ '^Test' && pos[1] =~ '^test_'
      " ...and highlight the name in the buffer.
      " call snakecharmer#pytest#HiInterestingWord(1, pos[1])
      call HiInterestingWord(1, pos[1])

      " If it does, store it as the only test to execute...
      call snakecharmer#pytest#Switch('k', join(pos, ' and '), 0, 0)
      call snakecharmer#pytest#Switch('file', fn, 0, 1)
      return
    endif
  endif

  " If we're not setting a new test, just execute the last set one
  call snakecharmer#pytest#Run()
endfunction " }}}

function! snakecharmer#pytest#Unit() " {{{
  " Run all tests, disabling anything set by snakecharmer#pytest#Single().
  call s:reset_flags({'k': ['not Integration']})
endfunction " }}}

function! snakecharmer#pytest#Integration() " {{{
  " Run integration tests
  call s:reset_flags({'k': ['Integration']})
endfunction " }}}

function! snakecharmer#pytest#All() " {{{
  " Run everything!
  call s:reset_flags({})
endfunction " }}}

function! snakecharmer#pytest#Sniper() " {{{
  " Navigate to a test, creating a stub test class if it does not exist.
  " TODO: Fix case of util functions outside of classes
  " TODO: Fix case when not under method
  let fn = expand('%')
  if fn =~ 'test/'
    return
  endif

  " module/(file).py
  let pos = snakeskin#SnakeskinParse(fn).position()

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

  normal! zt
  normal! zM
  normal! zA
endfunction " }}}

function! snakecharmer#pytest#Browse(shift) " {{{
  let file = s:dir('log')

  if !filereadable(file)
    echohl Identifier
    echon 'No snakecharmer log file.'
    echohl None
    return
  endif

  let index = 0
  let errors = snakecharmer#pytest#ParseErrors()

  if !errors.has_errors()
    echohl Identifier
    echon 'No errors'
    echohl None
    return
  endif

  call errors.shift(a:shift)
endfunction " }}}

function! snakecharmer#pytest#ParseErrors() " {{{
  if exists('g:snakecharmer_pytest_error')
    " Yay cache!
    let d = g:snakecharmer_pytest_error
  else
    " No cache! Create new!
    let d = {}
    let d.fn = s:dir('log')
    let d.fn = '/home/thiderman/git/piper/.git/snakecharmer/log'
    let d.has_errors = function('s:tb_has_errors')
    let d.parse = function('s:tb_parse')
    let d.parse_errorfile = function('s:parse_errorfile')
    let d.shift = function('s:tb_shift')
  endif

  return d.parse()
endfunction " }}}

function! s:tb_shift(shift) dict abort " {{{
  if has_key(self, 'index') == 1
    " Make sure that the index loops over the list (+1 at the end should go to
    " start)
    let self.index = (self.index + a:shift) % len(self.errors)
  else
    let self.index = 0
  endif

  let error = self.errors[self.index]
  call error.edit()

  echohl Statement
  echon 'SnakeTest'
  echohl None
  echon ': '
  echohl Number
  echon self.index + 1
  echon '/'
  echon len(self.errors)
  echohl None
  echon ' - '
  echohl Function
  " TODO: Fix too wise messages
  echon substitute(error.lines[-1], '\s*$', '', '')
  echohl None
endfunction " }}}

function! s:tb_parse() dict abort " {{{
  if getftime(self.fn) != get(self, 'ftime', -1)
    " Either there is no cache yet or the file has changed. Do parse.
    let self.ftime = getftime(self.fn)
    let self.errors = self.parse_errorfile()
    let g:snakecharmer_pytest_error = self
  endif

  return self
endfunction " }}}

function! s:tb_has_errors() dict abort " {{{
  return len(self.errors)
endfunction " }}}

function! s:parse_errorfile() dict abort " {{{
  let blocks = []
  let block = []

  for line in readfile(self.fn)
    if line =~ '^\.'
      " Passing test. Ignore pls.
      continue
    endif

    " If the line begins with a word character, it's the beginning of a new block
    if line =~ '^\w'
      if block != []
        " Add the previous block to the list of vlocks
        let blocks = add(blocks, block)
      endif
      let block = [line]
    else
      let block = add(block, line)
    endif
  endfor

  if block == []
    " Nothing happened - there are no errors
    return []
  endif

  " Add the last block as well
  let blocks = add(blocks, block)
  return s:generate_error_objects(blocks)
endfunction " }}}

function! s:generate_error_objects(blocks) " {{{
  let data = []

  for block in a:blocks
    let err = {}
    let err.lines = block
    let err.tb_lines = filter(err.lines[1:], 'v:val !~ "^ \\w   "')

    let spl = split(err.lines[0][2:], '::')
    let err.code = err.lines[0][0]
    let err.filename = spl[0]
    let err.cls = spl[1]
    let err.method = spl[3]
    " TODO: These can be multiline for AssertionErrors
    " let err.msg = err.lines[-1][5:]

    let err.as_qf = function('s:error_as_qf')
    let err.edit = function('s:error_edit')

    let data = add(data, err)
  endfor

  return data
endfunction " }}}

function! s:error_as_qf() dict abort " {{{
  let qf = []

  for x in range(len(self.tb_lines))
    if x % 2 == 1
      " Odd lines are handled on the even lines since they come in pairs
      continue
    endif

    let meta = split(self.tb_lines[x][1:], ':')
    let line = self.tb_lines[x+1][5:]

    let qfline = {}
    let qfline.filename = meta[0]
    let qfline.lnum = meta[1]
    let qfline.text = line

    if qfline.filename =~ '/site-packages/mock.py$'
      " We know, there was a mock patch...
      continue
    endif

    let qf = add(qf, qfline)
  endfor

  return qf
endfunction " }}}

function! s:error_edit() dict abort " {{{
  let qf = self.as_qf()
  silent only
  silent! exec 'edit' self.filename
  call setpos('.', [0, qf[0].lnum, 0, 0])

  " First of the line
  silent normal! ^
  " Focus just this fold
  silent normal! zMzAzz

  " Fill the quickfix list with the traceback and open it passively. Open it
  " with the default size unless it's larger.
  call setqflist(qf)
  silent exec 'copen' len(qf) < 10 ? 10 : len(qf)
  wincmd w

  let w:quickfix_title = self.lines[-1]
endfunction " }}}

function! snakecharmer#pytest#Start() " {{{
  if s:tmux('display -p "#{window_panes}"') > 1
    return
  endif

  let dir = getcwd()
  let script = globpath(&rtp, 'script/snakecharmer')
  silent! exec '!tmux split-window -h -d -p 33 -c' dir script '& &> /dev/null'
endfunction " }}}

function! s:tmux(...) " {{{
  let cmd = 'tmux ' . join(a:000, '')
  return system(cmd)
endfunction " }}}

function! s:camelize(s) " {{{
  if a:s =~ '_'
    " Move from snake_case to CamelCase.
    " http://vim.wikia.com/wiki/Converting_variables_to_or_from_camel_case
    let pat = '\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)'
  else
    " Just capitalize the first letter
    let pat = '^\(.\)\(.*\)'
  endif
  return substitute(a:s, pat , '\u\1\2', 'g')
endfunction " }}}

function! s:dir(...) " {{{
  let ret = getcwd() . '/.git/snakecharmer'
  if !isdirectory(ret)
    call mkdir(ret, 'p')
  endif

  if len(a:000) != 0
    let ret .= '/' . a:1
    if ret =~ '/$' && !isdirectory(ret)
      call mkdir(ret, 'p')
    endif
  endif

  return ret
endfunction " }}}

function! s:reset_flags(flags) abort " {{{
  call clearmatches()
  let dir = s:dir('switches/')

  " Kill all the old flags
  for fn in split(globpath(dir, '*'), '\n')
    if filereadable(fn)
      call delete(fn)
    endif
  endfor

  " Set the new flags
  for [fn, lines] in items(a:flags)
    call writefile(lines, dir . '/' . fn, "b")
  endfor

  call snakecharmer#pytest#Run()
endfunction " }}}
