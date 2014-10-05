" Function that takes the argument from an __init__ constructor and makes sure
" that there are assigments for all of them
function! SnakeArgs() " {{{
  let fn = expand('%')
  let skin = SnakeskinParse(fn)

  if skin.position()[-1] != '__init__'
    return
  endif

  let init_lnr = search('__init__', 'bn')
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
endfunction " }}}

function! s:get_args(lnr) " {{{
  let line = getline(a:lnr)
  let str = matchlist(line, '.*(\(.*\)):')[1]

  let args = split(str, ', ')
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
