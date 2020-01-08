" Copyright 2017 Google Inc. All rights reserved.
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


function! s:EnsureIsSyscall(Value) abort
  if type(a:Value) == type({}) &&
      \ has_key(a:Value, 'Call') &&
      \ maktaba#function#HasSameName(
          \ a:Value.Call, function('maktaba#syscall#Call'))
    return a:Value
  endif
  throw maktaba#error#BadValue(
      \ 'Not a valid matkaba.Syscall: %s', string(a:Value))
endfunction


""
" @public
" Format lines in the current buffer via a formatter invoked by {cmd} (a
" |maktaba.Syscall|). The command includes the explicit range line numbers to
" use, if any.
"
" @throws ShellError if the {cmd} system call fails
function! codefmt#formatterhelpers#Format(cmd) abort
  call s:EnsureIsSyscall(a:cmd)
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
" formatting (invoked by {cmd}, a |maktaba.Syscall|), using a hacky strategy
" of sending those lines to the formatter in isolation.
"
" If invoking this hack, please make sure to file a feature request against
" the tool for range formatting and post a URL for that feature request above
" code that calls it.
"
" @throws ShellError if the {cmd} system call fails
function! codefmt#formatterhelpers#AttemptFakeRangeFormatting(
    \ startline, endline, cmd) abort
  call maktaba#ensure#IsNumber(a:startline)
  call maktaba#ensure#IsNumber(a:endline)
  call s:EnsureIsSyscall(a:cmd)

  let l:lines = getline(1, line('$'))
  let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

  let l:result = a:cmd.WithStdin(l:input).Call()
  let l:formatted = split(l:result.stdout, "\n")
  " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
  let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
  let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]

  call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
endfunction
