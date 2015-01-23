" Copyright 2014 Google Inc. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.

""
" @section Formatters, formatters
" This plugin has two built-in formatters: clang-format and gofmt. More
" formatters can be registered by other plugins that integrate with codefmt.
"
" @subsection Default formatters
" Codefmt will automatically use a default formatter for certain filetypes if
" none is explicitly supplied via an explicit arg to @command(FormatCode) or the
" @setting(b:codefmt_formatter) variable. The default formatter may also depend
" on what plugins are enabled or what other software is installed on your
" system.
"
" The current list of defaults by filetype is:
"   * cpp, proto, javascript: clang-format
"   * go: gofmt


call maktaba#library#Require('codefmtlib')


let s:plugin = maktaba#plugin#Get('codefmt')
let s:plugin_root = expand('<sfile>:p:h:h:h')


" Formatter: clang-format
if !exists('s:clangformat')
  let s:clangformat = {
      \ 'name': 'clang-format',
      \ 'setup_instructions': 'Install clang-format from ' .
          \ 'http://clang.llvm.org/docs/ClangFormat.html and ' .
          \ 'configure the clang_format_executable flag'}

  function s:clangformat.IsAvailable() abort
    return executable(s:plugin.Flag('clang_format_executable'))
  endfunction

  function s:clangformat.AppliesToBuffer() abort
    return &filetype is# 'cpp' || &filetype is# 'proto' ||
        \ &filetype is# 'javascript'
  endfunction

  ""
  " Reformat buffer with clang-format, only targeting [ranges] if given.
  function s:clangformat.FormatRanges(ranges) abort
    let l:Style_value = s:plugin.Flag('clang_format_style')
    if type(l:Style_value) is# type('')
      let l:style = l:Style_value
    elseif maktaba#value#IsCallable(l:Style_value)
      let l:style = maktaba#function#Call(l:Style_value)
    else
      throw maktaba#error#WrongType(
          \ 'clang_format_style flag must be string or callable. Found %s',
          \ string(l:Style_value))
    endif
    let l:cmd = [
        \ s:plugin.Flag('clang_format_executable'),
        \ '-style', l:style]
    let l:fname = expand('%:p')
    if !empty(l:fname)
      let l:cmd += ['-assume-filename', l:fname]
    endif

    if empty(a:ranges)
      return
    endif
    for [l:startline, l:endline] in a:ranges
      call maktaba#ensure#IsNumber(l:startline)
      call maktaba#ensure#IsNumber(l:endline)
      let l:cmd += ['-lines', l:startline . ':' . l:endline]
    endfor

    let l:input = join(getline(1, line('$')), "\n")
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")
    call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
  endfunction

  call codefmtlib#AddDefaultFormatter(s:clangformat)
endif


" Formatter: gofmt
if !exists('s:gofmt')
  let s:gofmt = {
      \ 'name': 'gofmt',
      \ 'setup_instructions': 'Install gofmt or goimports and ' .
          \ 'configure the gofmt_executable flag'}

  function s:gofmt.IsAvailable() abort
    return executable(s:plugin.Flag('gofmt_executable'))
  endfunction

  function s:gofmt.AppliesToBuffer() abort
    return &filetype is# 'go'
  endfunction


  ""
  " Reformat the current buffer with gofmt or the binary named in
  " @flag(gofmt_executable), only targeting the range between {startline} and
  " {endline}.
  function s:gofmt.FormatRange(startline, endline) abort
    " Hack range formatting by formatting range individually, ignoring context.
    let l:cmd = [ s:plugin.Flag('gofmt_executable') ]
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
      let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []

      let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]
      call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^\<standard input\>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse gofmt error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  call codefmtlib#AddDefaultFormatter(s:gofmt)
endif

" Formatter: autopep8
if !exists('s:autopep8')
  let s:autopep8 = {
      \ 'name': 'autopep8',
      \ 'setup_instructions': 'Install autopep8 and '}

  function s:autopep8.IsAvailable() abort
    return executable(s:plugin.Flag('autopep8_executable'))
  endfunction

  function s:autopep8.AppliesToBuffer() abort
    return &filetype is# 'python'
  endfunction


  ""
  " Reformat the current buffer with autopep8 or the binary named in
  " @flag(autopep8_executable), only targeting the range between {startline} and
  " {endline}.
  function s:autopep8.FormatRange(startline, endline) abort
    " Hack range formatting by formatting range individually, ignoring context.
    let l:cmd = [ s:plugin.Flag('autopep8_executable'), "-"  ]
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
      let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []

      let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]
      call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^\<standard input\>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse autopep8 error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  call codefmtlib#AddDefaultFormatter(s:autopep8)
endif
""
" Detects whether a formatter has been defined for the current buffer/filetype.
function! codefmt#IsFormatterAvailable() abort
  let l:formatters = copy(codefmtlib#GetFormatters())
  let l:is_available = 'v:val.AppliesToBuffer() && v:val.IsAvailable()'
  return !empty(filter(l:formatters, l:is_available)) ||
        \ !empty(get(b:, 'codefmt_formatter'))
endfunction

""
" Get formatter based on [name], @setting(b:codefmt_formatter), and defaults.
" If no formatter is available, shout error and return 0.
function! s:GetFormatter(...) abort
  if a:0 >= 1
    let l:explicit_name = a:1
  elseif !empty(get(b:, 'codefmt_formatter'))
    let l:explicit_name = b:codefmt_formatter
  endif
  let l:formatters = codefmtlib#GetFormatters()
  if exists('l:explicit_name')
    " Explicit name passed.
    let l:selected_formatters = filter(
        \ copy(l:formatters), 'v:val.name == l:explicit_name')
    if empty(l:selected_formatters)
      " No such formatter.
      call maktaba#error#Shout(
          \ '"%s" is not a supported formatter.', l:explicit_name)
      return
    endif
    let l:formatter = l:selected_formatters[0]
    if !l:formatter.IsAvailable()
      " Not available. Print setup instructions if possible.
      let l:error = 'Formatter "%s" is not available.'
      if has_key(l:formatter, 'setup_instructions')
        let l:error .= ' Setup instructions: ' . l:formatter.setup_instructions
      endif
      call maktaba#error#Shout(l:error, l:explicit_name)
      return
    endif
  else
    " No explicit name, use default.
    let l:default_formatters = filter(
        \ copy(l:formatters), 'v:val.AppliesToBuffer() && v:val.IsAvailable()')
    if !empty(l:default_formatters)
      let l:formatter = l:default_formatters[0]
    else
      call maktaba#error#Shout(
          \ 'Not available. codefmt doesn''t have a default formatter for ' .
          \ 'this buffer.')
      return
    endif
  endif

  return l:formatter
endfunction

""
" Applies [formatter] to the current buffer.
function! codefmt#FormatBuffer(...) abort
  let l:formatter = a:0 >= 1 ? s:GetFormatter(a:1) : s:GetFormatter()
  if l:formatter is# 0
    return
  endif

  try
    if has_key(l:formatter, 'Format')
      call l:formatter.Format()
    elseif has_key(l:formatter, 'FormatRange')
      call l:formatter.FormatRange(1, line('$'))
    elseif has_key(l:formatter, 'FormatRanges')
      call l:formatter.FormatRanges([[1, line('$')]])
    endif
  catch
    call maktaba#error#Shout('Error formatting file: %s', v:exception)
  endtry

  let l:cmd = ":FormatCode " . l:formatter.name . "\<CR>"
  silent! call repeat#set(l:cmd)
endfunction

""
" Applies [formatter] to buffer lines from {startline} to {endline}.
function! codefmt#FormatLines(startline, endline, ...) abort
  call maktaba#ensure#IsNumber(a:startline)
  call maktaba#ensure#IsNumber(a:endline)
  let l:formatter = a:0 >= 1 ? s:GetFormatter(a:1) : s:GetFormatter()
  if l:formatter is# 0
    return
  endif
  try
    if has_key(l:formatter, 'FormatRange')
      call l:formatter.FormatRange(a:startline, a:endline)
    elseif has_key(l:formatter, 'FormatRanges')
      call l:formatter.FormatRanges([[a:startline, a:endline]])
    elseif has_key(l:formatter, 'Format')
      if a:startline is# 1 && a:endline is# line('$')
        " Allow formatting 1,$ as non-range if range formatting isn't supported.
        call l:formatter.Format()
      else
        call maktaba#error#Shout(
            \ 'Range formatting not supported for %s', l:formatter.name)
      endif
    endif
  catch
    call maktaba#error#Shout('Error formatting file: %s', v:exception)
  endtry
  let l:cmd = ":FormatLines " . l:formatter.name . "\<CR>"
  let l:lines_formatted = a:endline - a:startline + 1
  silent! call repeat#set(l:cmd, l:lines_formatted)
endfunction

""
" @public
" Suitable for use as 'operatorfunc'; see |g@| for details.
" The type is ignored since formatting only works on complete lines.
function! codefmt#FormatMap(type) range
  call codefmt#FormatLines(line("'["), line("']"))
endfunction

""
" Generate the completion for supported formatters. Lists available formatters
" that apply to the current buffer first, then unavailable formatters that
" apply, then everything else.
function! codefmt#GetSupportedFormatters(ArgLead, CmdLine, CursorPos)
  let l:groups = [[], [], []]
  for l:formatter in codefmtlib#GetFormatters()
    let l:key = l:formatter.AppliesToBuffer() ? (
        \ l:formatter.IsAvailable() ? 0 : 1) : 2
    call add(l:groups[l:key], l:formatter.name)
  endfor
  return join(l:groups[0] + l:groups[1] + l:groups[2], "\n")
endfunction

