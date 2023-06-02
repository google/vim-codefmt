" Copyright 2020 Google Inc. All rights reserved.
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


let s:plugin = maktaba#plugin#Get('codefmt')


" TODO(google/vim-maktaba#255): Use maktaba's when dropping support for 1.16.0.
function! s:ValueAsList(Value_or_values) abort
  return maktaba#value#IsList(a:Value_or_values) ?
      \ a:Value_or_values : [a:Value_or_values]
endfunction


""
" @public
" Checks if the given {filetype} matches {expected} filetype(s).
"
" When checking a dotted filetype name (like "c.doxygen"), returns true if any
" piece matches expected filetype(s).
"
" Usage examples: >
"   if codefmt#formatterhelpers#FiletypeMatches(&filetype, 'c')
" < >
"   if codefmt#formatterhelpers#FiletypeMatches(&filetype, ['c', 'cpp'])
" <
" @throws WrongType
function! codefmt#formatterhelpers#FiletypeMatches(filetype, expected) abort
  call maktaba#ensure#TypeMatchesOneOf(a:expected, ['', ['']])
  let l:expected = s:ValueAsList(a:expected)
  " TODO(google/vim-maktaba#256): Drop this check when redundant with above.
  for l:expected_ft in l:expected
    call maktaba#ensure#IsString(l:expected_ft)
  endfor
  " Check if filetypes match expected (splitting & looping to help support
  " dot-separated filetype names).
  for l:filetype in split(a:filetype, '\m\.', 0)
    if index(l:expected, l:filetype) >= 0
      return 1
    endif
  endfor
  return 0
endfunction


""
" @public
" Format lines in the current buffer via a formatter invoked by {cmd}, which
" is a system call represented by either a |maktaba.Syscall| or any argument
" accepted by |maktaba#syscall#Create()|. The command must include any
" arguments for the explicit range line numbers to use, if any.
"
" @throws ShellError if the {cmd} system call fails
function! codefmt#formatterhelpers#Format(cmd) abort
  let l:lines = getline(1, line('$'))
  let l:input = join(l:lines, "\n")

  let l:result = maktaba#syscall#Create(a:cmd).WithStdin(l:input).Call()
  let l:formatted = split(l:result.stdout, "\n")

  call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
endfunction


""
" @public
" Attempt to format a range of lines from {startline} to {endline} in the
" current buffer via a formatter that doesn't natively support range
" formatting, which is invoked via {cmd} (a system call represented by either
" a |maktaba.Syscall| or any argument accepted by |maktaba#syscall#Create()|).
" It uses a hacky strategy of sending those lines to the formatter in
" isolation, which gives bad results if the code on those lines isn't
" a self-contained block of syntax or is part of a larger indent.
"
" If invoking this hack, please make sure to file a feature request against
" the tool for range formatting and post a URL for that feature request above
" code that calls it.
"
" If [ignoreerrors] is nonzero, the syscall ignores errors. This can be helpful
" for formatters that return nonzero results for reasons unrelated to
" formatting.
"
" If [skipfirstnlines] is set to a nonzero number N, the first
" N lines of the formatter output are trimmed. This can be used to trim
" always-present headers.
"
" @default ignoreerrors=0
" @default skipfirstnlines=0
" @throws ShellError if the {cmd} system call fails (and [ignoreerrors] is 0)
" @throws WrongType
function! codefmt#formatterhelpers#AttemptFakeRangeFormatting(
    \ startline, endline, cmd, ...) abort
  call maktaba#ensure#IsNumber(a:startline)
  call maktaba#ensure#IsNumber(a:endline)

  let l:ignoreerrors = a:0 >= 1 ? a:1 : 0
  let l:skipfirstnlines = a:0 >= 2 ? a:2 : 0

  call maktaba#ensure#IsNumber(l:ignoreerrors)
  call maktaba#ensure#IsNumber(l:skipfirstnlines)

  let l:lines = getline(1, line('$'))
  let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

  let l:result =
      \ maktaba#syscall#Create(a:cmd).WithStdin(l:input).Call(!l:ignoreerrors)
  let l:formatted = split(l:result.stdout, "\n")
  " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
  let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
  let l:full_formatted = l:before + l:formatted[l:skipfirstnlines :]
      \ + l:lines[a:endline :]

  call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
endfunction


""
" @public
" Resolve a flag (function, string or array) to a normalized array, with special
" handling to convert a spaceless string to a single-element array. This is the
" common case for executables, and more importantly, is backward-compatible for
" existing user settings.
"
" @throws WrongType if the flag doesn't resolve to a string or array
function! codefmt#formatterhelpers#ResolveFlagToArray(flag_name) abort
  let l:FlagFn = s:plugin.Flag(a:flag_name)
  if maktaba#value#IsFuncref(l:FlagFn)
    let l:value = maktaba#function#Call(l:FlagFn)
  else
    let l:value = l:FlagFn
  endif

  " After (conditionally) calling the function, the resulting value should be
  " either a list that we can use directly, or a string that we can treat as
  " a single-element list, mainly for backward compatibility.
  if maktaba#value#IsString(l:value)
    if l:value =~ '\s'
      " Uh oh, there are spaces in the string. Rather than guessing user intent
      " with shell quoting and word splitting, handle this (hopefully unusual)
      " case by telling them to update their configuration.
      throw maktaba#error#WrongType(
            \ '%s flag is a string with spaces, please make it a list. ' .
            \ 'Resolved value was: %s',
            \ a:flag_name, l:value)
    endif
    " Convert spaceless string to single-element list.
    return [l:value]
  elseif maktaba#value#IsList(l:value)
    return l:value
  endif

  throw maktaba#error#WrongType(
      \ '%s flag should be a list after calling. Found %s',
      \ a:flag_name, maktaba#value#TypeName(l:value))
endfunction
