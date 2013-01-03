function! s:strip(s, ...)
  let string = a:0 ? substitute(a:s, ',\s*$', '', 'g') : a:s
  return substitute(string, '\(^\s*\|\s*$\)', '', 'g')
endfunction

function! PythonFormatExpr(lnum, count, char) abort
  let line = getline(a:lnum)
  let linelength = len(line)
  let shift = indent(a:lnum)
  let insertion = a:char != ""

  " Not yet above the textwidth and an insertion has been made;
  " nothing should be done.
  if linelength <= &tw && insertion
    return
  endif

  let match = matchlist(line, '^\(.*[({\[]\)\(.\{-}\)\([)}\]]\s*\)\?$')
  if match != []

    let start = match[1]
    let end = match[3]

    let spl = split(match[2], ',\s*')
    let data = map(spl, 'repeat(" ", shift + &sw) . s:strip(v:val) . ","')

    let data = insert(data, start)
    if end == ""
      let end = ")"
    endif
    let end = repeat(' ', shift) . end
    let data = add(data, end)

    " Set the line to the newly formatted ones
    call setline(a:lnum, data)

    " If this was an insertion, make sure to retain the cursor position.
    if insertion
      let pos = getpos('.')
      let pos[1] += len(data) - 2
      let pos[2] = match(data[-2], '"\?,') + 1
      call setpos('.', pos)
    endif
  endif
endfunction

if &ft == "python"
  setl fex=PythonFormatExpr\(v:lnum,\ v:count,\ v:char\)
endif

augroup pythonexpr
  au!
  au BufWritePost format.vim so %
augroup END
