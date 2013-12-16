let s:opening = '[({:\[]\s*\(#.*\)\?$'
let s:closing = '^\s*[)}\]]\+\s*$'

function! s:strip(s, ...)
  let string = a:0 ? substitute(a:s, ',\s*$', '', 'g') : a:s
  return substitute(string, '\(^\s*\|\s*$\)', '', 'g')
endfunction

function! s:replace(lnum, data)
  call setline(a:lnum, a:data[0])
  if len(a:data) > 1
    call append(a:lnum, a:data[1:])
  endif
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

  " If this matches, we have a long statement that is over the line
  let match = matchlist(line, '^\(.*[({\[]\)\(.\{-}\)\([)}\]]\s*\)$')
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
    call s:replace(a:lnum, data)

    let pos = getpos('.')
    if insertion
      " If this was an insertion, make sure to retain the cursor position.
      let offset = linelength - len(start)
      let pos[1] += len(data) - 2 " Line should be bottom-most content line
      let pos[2] = data[-2] =~ "['\"],$" ? len(data[-2]) - 1 : len(data[-2])
    else
      " If not, place the cursor on the beginning of the first item line
      let pos[1] += 1
      let pos[2] = shift + &sw + 1
    endif
    call setpos('.', pos)
    return
  endif

  if a:count
    let lines = getline(a:lnum, a:lnum + a:count - 1)
    " Check if we are formatting a block that looks like a long call
    if lines[0] =~ s:opening && lines[-1] =~ s:closing
      let content = join(map(lines[1:-2], "s:strip(v:val, 1)"), ', ')
      let closer = s:strip(lines[-1])
      let final = lines[0] . content . closer

      " If the compressed line is short enough to fit on one line, just fold
      " them all back into one.
      if len(final) < &tw
        exe '.+1,.+'.(a:count - 1).'delete'
        call setline(a:lnum, final)

        " Reset the position to be on the beginning of the first argument
        let pos = getpos('.')
        let pos[1] = a:lnum
        let pos[2] = len(lines[0]) + 1
        call setpos('.', pos)
      endif
    endif
  endif
endfunction

if &ft == "python"
  setl fex=PythonFormatExpr\(v:lnum,\ v:count,\ v:char\)
endif
