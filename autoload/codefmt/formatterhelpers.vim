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
" @throws ShellError if the {cmd} system call fails
function! codefmt#formatterhelpers#AttemptFakeRangeFormatting(
    \ startline, endline, cmd) abort
  call maktaba#ensure#IsNumber(a:startline)
  call maktaba#ensure#IsNumber(a:endline)

  let l:lines = getline(1, line('$'))
  let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

  let l:result = maktaba#syscall#Create(a:cmd).WithStdin(l:input).Call()
  let l:formatted = split(l:result.stdout, "\n")
  " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
  let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
  let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]

  call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
endfunction
