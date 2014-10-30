" Function that takes the argument from an __init__ constructor and makes sure
" that there are assigments for all of them
function! SnakeArgs() abort " {{{
  if getline('.') !~ 'def __init__(self, \w.*)'
    return
  endif

  let pos = getpos('.')
  let init_lnr = line('.')
  let indent = s:get_indent(init_lnr)

  let args = s:get_args(init_lnr)[1:]
  let args = map(args, "substitute(v:val, '\\(.*\\)', 'self.\\1 = \\1', '')")
  let args = map(args, 'indent . v:val')

  let lnr = init_lnr + 1
  let end_lnr = s:get_end_line(lnr)

  let lnrs = range(lnr, end_lnr)
  for x in lnrs
    let l = getline(x)
    let y = index(lnrs, x)

    if y < len(args)
      " Set to the generated ones
      let other = args[y]
      if l != other
        call setline(x, other)
      endif
    else
      " Delete remaining present args
      exe x . 'delete _'
    endif
  endfor

  if len(lnrs) < len(args)
    call append(end_lnr, args[len(lnrs):])
  endif
  call setpos('.', pos)
endfunction " }}}

function! s:get_args(lnr) " {{{
  let line = getline(a:lnr)
  let str = matchlist(line, '.*(\(.*\)):')[1]

  let args = split(str, ',\s\?')
  let args = map(args, "substitute(v:val, '\\(=.*\\)', '', '')")

  return args
endfunction " }}}

function! s:get_end_line(lnr) " {{{
  let ret = a:lnr
  let line = getline(ret)

  while match(line, '^\s*self') != -1
    let ret += 1
    let line = getline(ret)
  endwhile

  return ret - 1
endfunction " }}}

function! s:get_indent(lnr) " {{{
  let line = getline(a:lnr)
  return matchstr(line, '^\(\s*\)') . '    '
endfunction " }}}

" Function that looks at the above test to see if there are mocks, and if so
" checks if the mock arguments have been properly provided
function! SnakeMockArgs() " {{{
  if getline('.') !~ '@mock.patch('
    return
  endif
  let test_lnr = search('def test_', 'n')

  let mocks = s:get_mocks(test_lnr - 1)
  let args = map(mocks, 's:clean_mock_arg(v:val)')
  let args = insert(args, 'self')

  let test = getline(test_lnr)
  let rep = '\1' . join(args, ', ') . '\3'
  let res = substitute(test, '\(.*(\)\(.*\)\():\)', rep, '')

  if res != test
    call setline(test_lnr, res)
  endif
endfunction

function! s:get_mocks(lnr) " {{{
  let mocks = []
  let lnr = a:lnr

  let line = getline(lnr)
  while line =~ '@mock.patch('
    " Ignore commented mocks
    if line !~ '^\s\+#'
      let mocks = add(mocks, line)
    endif

    let lnr -= 1
    let line = getline(lnr)
  endwhile

  return mocks
endfunction " }}}

function! s:clean_mock_arg(arg) " {{{
  let arg = a:arg[17:]
  let arg = arg[:-3]
  let arg = split(arg, '\.')[-1]

  " If the arg contains underscores, compress it from `arg_func` to `af`
  if arg =~ '_'
    let arg = join(map(split(arg, '_'), 'v:val[0]'), '')
  endif

  return arg
endfunction " }}}
