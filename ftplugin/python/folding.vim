" Variables {{{1

" Triple quote or triple singlequote. Tricky to get right in vim, appearantly.
let ds = '\("""\|'."'''".'\)'

let s:import = '^\(#\s*\)\?\(import\|from\)'
let s:modulelevel = '^#\?[A-Z_0-9]\+\s*='
let s:opening = '[({:\[]\s*\(#.*\)\?$'
let s:closing = '^\s*[)}\]]\+\s*$'
let s:def = '^\s*\(class\|def\)\s\S'
let s:multiline_def = s:def . '.*\(,\|(\)\s*$'
let s:decorator = '^\s*#\?\s*@'
let s:docstring = '^\s*' . ds
let s:oneline_docstring = s:docstring . '[^"]\+'. ds .'\s*$'
let s:commented = '^\s*#\(\s*coding.*\|!/.*\)\@!'

" }}}
" Helpers {{{1

function! s:pline(lnum)
  return getline(prevnonblank(a:lnum - 1))
endfunction

function! s:nline(lnum)
  return getline(nextnonblank(a:lnum + 1))
endfunction

" }}}
" Main folding {{{1

function! PythonFold(lnum)
  let line = getline(a:lnum)
  let level = indent(a:lnum) / &shiftwidth + 1

  " Imports {{{2

  " Group all module-level imports
  if line =~ s:import
    return 2
  endif

  " If the line is empty, the previous line was an import, and...
  if line == '' && s:pline(a:lnum) =~ s:import
    if s:nline(a:lnum) =~ s:import
      " ...the next one is as well, close the last one
      return '<2'
    elseif getline(a:lnum + 2) != ''
      " ...the next one isn't, break the entire import fold group
      return '<1'
    endif
  endif

  if line =~ s:closing && s:nline(a:lnum) =~ s:import
    return 2
  endif

  " Group module-level variables
  if line =~ s:modulelevel
    let level += 1
    if line =~ s:opening
      return '>' . level
    endif

    if line =~ s:closing
      return '<' . level
    endif

    return 1
  endif

  " }}}
  " Defs {{{2

  " If we are on a class or def and the previous line was a decorator, just
  " continue the fold
  if line =~ s:def && s:pline(a:lnum) =~ s:decorator
    return '='
  endif

  " If we are a decorator and the previous line was empty, we start a new fold
  if line =~ s:decorator && getline(a:lnum - 1) == ''
    return '>' . level
  endif

  " If we are on the opening statment of a multiline def, we start a new foldj
  if line =~ s:multiline_def
    return '>' . level
  endif

  " }}}
  " Docstrings {{{2

  if line =~ s:docstring && s:pline(a:lnum) =~ s:def
      " If we are on a docstring line that was preceded by a definition, we start
      " a docstring fold
    return '>' . level
  endif

  if line == '' && s:pline(a:lnum) =~ s:docstring
    let dsline = prevnonblank(a:lnum - 1)
    if getline(prevnonblank(dsline - 1)) !~ s:def
      return '<' . (indent(dsline) / &shiftwidth + 1)
    endif
  endif

  " }}}
  " Comments {{{2

  " If we are on a commented line and the previous line was empty, we open a new
  " fold for the block
  if line =~ s:commented && getline(a:lnum - 1) == ''
    return '>' . level
  endif

  " If we are on an opening line and the previous line was a comment, continue
  " the fold that was started by the comments
  if line =~ s:opening && getline(a:lnum - 1) =~ s:commented
    return '='
  endif

  " }}}
  " Openers and closers {{{2

  " A line that ends on colon or opening of brackets, or
  " a line with the first decorator for a class or a function
  " both start a new fold
  if line =~ s:opening
    " If the opener is the opener of a multiline def, just continue that fold
    " Check up to ten lines above, limited for performance.
    for x in range(10)
      if getline(a:lnum - x) =~ s:multiline_def
        return '='
      endif
    endfor

    return '>' . level
  endif

  " " A line that only consits of a closing bracket (or brackets) will close a fold
  if line =~ s:closing
    return '<' . level
  endif

  " }}}

  " let next = nextnonblank(a:lnum + 1)
  " if line != '' && indent(next) > indent(line)
  "   return ">" . level
  " endif

  " if line == '' && next == (a:lnum + 1)
  "   if indent(next) != indent(prevnonblank(a:lnum - 1))
  "     return "<" . level
  "   endif
  " endif

  return '='
endfunction

" }}}
" Foldtext {{{1

function! FoldText_python(foldstart)
  let foldstart = a:foldstart
  let line = getline(foldstart)

  " If the fold is on a comment, go down to the line that should have opened
  " the fold and use that line as the foldtext
  while line =~ s:commented
    let foldstart += 1
    let line = getline(foldstart)
  endwhile

  " If the fold is on a decorator, go down to the definition and show that line
  " as the foldtext
  while line =~ s:decorator
    let foldstart += 1
    let line = getline(foldstart)
  endwhile

  " When the foldline is a definition, only show up until the opening paren.
  if line =~ s:def
    let line = substitute(line, '(.*', '(...', '')
  endif

  " If the fold is of a docstring, join as many lines as possible as the
  " foldtext
  if line =~ s:docstring
    if line =~ s:oneline_docstring
      return line
    endif

    let tw = &tw ? &tw : 79
    while len(line) <= tw
      let foldstart += 1
      let newline = getline(foldstart)
      let line = line . ' ' . substitute(newline, '\(^\s\+\|\s\+$\)', "", "")

      " If the next line is the end of the docstring, add the ending characters
      " and break the loop
      let nextline = getline(foldstart + 1)
      if nextline =~ s:docstring
        let line = line . ' ' . substitute(nextline, '\(^\s\+\|\s\+$\)', "", "")
        break
      endif
    endwhile
  endif

  return line
endfunction

" }}}
