" plugin/snakeskin.vim
" Author:       Lowe Thiderman <lowe.thiderman@gmail.com>

if exists('g:loaded_snakeskin') || &cp
  finish
endif
let g:loaded_snakeskin = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists('g:snakeskin')
  let g:snakeskin = {}
endif

" Public API {{{1

function! SnakeskinParse(fn, ...)
  let fn = fnamemodify(a:fn, ':p')
  if !filereadable(fn)
    " echo "Error: File not found."
    return {}
  endif

  " if has_key(g:snakeskin, fn) && !a:0
  "   return g:snakeskin[fn]
  " endif

  let d = {}
  let d.fn = fn
  let d.indent = function('s:get_indent')
  let d.get_data = function('s:get_data')
  let d.data = d.get_data()
  let d.get_line = function('SnakeskinGetLine')
  let d.get_children = function('SnakeskinGetChildren')
  let d.get_level = function('SnakeskinGetLevel')
  let d.complete = function('SnakeskinComplete')
  let d.position = function('SnakeskinPosition')
  let d.closest = function('SnakeskinClosestParent')

  let g:snakeskin[fn] = d
  return d
endfunction
" }}}
" Statusline {{{1

function! SnakeskinPosition() dict abort
  let lnr = getpos('.')[1]
  let closest = self.closest(lnr)

  if closest == []
    return []
  endif

  let idx = index(self.data, closest)
  let depth = closest[1]
  let ret = [closest[3]]

  " Loop the data backwards, starting from the closest parent we found
  for data in reverse(copy(self.data)[0:idx])
    " If we are one level above what we were last time, we have a match
    if depth != data[1]
      let ret = insert(ret, data[3])
      let depth -= 1
    endif

    " If we are at the top, we can break.
    if depth == 0
      break
    endif
  endfor

  return ret
endfunction

function! SnakeskinClosestParent(lnr) dict abort
  " Cursor positioned above earliest definition.
  if a:lnr < self.data[0][0]
    return []
  endif

  for idx in range(len(self.data))
    if idx + 1 == len(self.data)
      return self.data[-1]
    endif

    let data = self.data[idx]
    let next = self.data[idx + 1]

    if a:lnr >= data[0] && a:lnr < next[0]
      return data
    endif
  endfor
endfunction

" }}}
" Core helpers {{{1

function! s:get_indent() dict abort
  " if has_key(self, '_indent')
  "   return self._indent  " Simple cache
  " endif

  let indent = ""
  let idx = 0

  let lines = readfile(self.fn)
  for line in lines
    if line =~ ':\s*$'
      let idx = index(lines, line)
      break
    endif
  endfor

  if idx == 0
    " No indented lines. Possibly just a new file.
    " Default to a sensible PEP008 default.
    let indent = "    "
  endif

  while indent == ""
    let idx = idx + 1

    if idx == len(lines)
      " File with syntax error, eg  def wat():  was the last non-empty
      " line. This stops the loop from total hanging.
      break
    endif

    let line = lines[idx]

    if line !~ '^\s\+$'
      let indent = matchstr(line, '^\s\+')
    endif
  endwhile

  let self._indent = indent
  return indent
endfunction

function! s:get_data() dict abort
  let data = []
  let lnr = 0

  for line in readfile(self.fn)
    let lnr = lnr + 1
    if line =~ '^\s\+$'
      continue
    endif

    let m = matchlist(line, '\(def\|class\) \(\w\+\)(.*:')
    if len(m) != 0
      " TODO: Test this with tabs. :'@
      let level = len(matchstr(line, '^\s*')) / len(self.indent())
      let data = add(data, [lnr, level, m[1], m[2]])
    endif
  endfor

  return data
endfunction

function! s:strip(s)
  return substitute(substitute(a:s, '^\s\+', '', ''), '\s\+$', '', '')
endfunction


" }}}
" Completion {{{1

function! SnakeskinComplete(A,P,L) abort
  let spl = split(a:P)
  if len(spl) == 1 || len(spl) <= 2 && a:P !~ '\s\+$'
    return SnakeskinFileCompletion(a:A, a:P, a:L)
  endif
  return SnakeskinPythonCompletion(spl[1], spl[2:], a:A, a:P, a:L)
endfunction

function! SnakeskinFileCompletion(A, P, L) abort
  " Re-implementation of the file completion. Needed as we need additional
  " completion after the file selection.
  let ret = []

  if stridx(a:A, '/') != -1
    let dir = substitute(a:A, '\w\+$', '', '')
  else
    let dir = './'
  endif

  for fn in split(globpath(dir, '*'), '\n')
    if !isdirectory(fn) && fn !~ '\.py$'
      continue
    endif

    let fn = substitute(fn, '^\./', '', '')
    if isdirectory(fn)
      if !filereadable(fn . '/__init__.py')
        " Skip non-python directories
        continue
      endif
      let fn = fn . '/'
    endif

    if fn =~ '^' . a:A
      let ret = add(ret, fn)
    endif
  endfor

  if len(ret) == 1 && filereadable(ret[0])
    let ret = [ret[0] . ' ']
  endif
  return ret
endfunction

function! SnakeskinPythonCompletion(fn, words, A, P, L) abort
  let ret = []
  let data = SnakeskinParse(a:fn)
  if data == {}
    return ret
  endif

  let words = a:words
  if len(words) == 0 || len(words) <= 1 && a:P !~ '\s\+$'
    let ret = data.get_level(0)
  else
    if words[-1] == a:A
      let words = words[:-2]
    endif
    let ret = data.get_children(words)
  endif

  let ret = sort(filter(map(ret, 'v:val[3]'), 'v:val =~# "^".a:A'))
  if len(ret) == 1
    let ret = [ret[0] . ' ']
  endif
  return ret
endfunction

" }}}
" Data traversing {{{1

function! SnakeskinGetLevel(level) dict abort
  return filter(deepcopy(self.data), 'v:val[1] == ' . a:level)
endfunction

function! SnakeskinGetChildren(names, ...) dict abort
  let ret = []
  let line = self.get_line(a:names)

  if line == []
    return ret
  endif

  let start = index(self.data, line) + 1  " Start on the line after the match...
  let depth = line[1] + 1 " ...and only grab it's children.

  for data in self.data[start :]
    if data[1] == depth
      let ret = add(ret, data)
    elseif data[1] < depth
      break
    endif
  endfor

  return ret
endfunction

function! SnakeskinGetLine(names, ...) dict abort
  let line = []
  let depth = 0

  for data in self.data
    if data[3] == s:strip(a:names[depth])
      let depth = depth + 1

      if depth == len(a:names)
        " If we are as deep as the list of arguments, we have found what we
        " were looking for!
        let line = data
        break
      endif
    elseif data[1] < depth
      " We have exited the class or function that we were scoping. The match
      " cannot be done.
      break
    endif
  endfor

  return line
endfunction


" }}}
" Commands {{{1

function! SnakeskinEdit(cmd, fn, ...) abort
  exe a:cmd a:fn

  if a:0
    let skin = SnakeskinParse(a:fn)
    " TODO: Abort if unskinnable
    let line = skin.get_line(a:000)

    if line == []
      return
    endif

    call setpos('.', [0, line[0], line[1] * len(skin.indent()) + 1, 0])
    normal zz
  endif
endfunction

" com! -nargs=+ -complete=customlist,SnakeskinComplete Py :call SnakeskinEdit('edit', <f-args>)
" com! -nargs=+ -complete=customlist,SnakeskinComplete PE :call SnakeskinEdit('edit', <f-args>)
" com! -nargs=+ -complete=customlist,SnakeskinComplete PV :call SnakeskinEdit('vsplit', <f-args>)
" com! -nargs=+ -complete=customlist,SnakeskinComplete PS :call SnakeskinEdit('split', <f-args>)
" com! -nargs=+ -complete=customlist,SnakeskinComplete PT :call SnakeskinEdit('tabedit', <f-args>)

" }}}

let &cpo = s:cpo_save
" vim:set sw=2 sts=2:
