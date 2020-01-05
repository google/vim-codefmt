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


function! codefmt#fish_indent#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'fish_indent',
      \ 'setup_instructions': 'Install fish_indent (https://fishshell.com/docs/current/commands.html#fish_indent)' .
          \ ' and configure the fish_indent_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('fish_indent_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'fish'
  endfunction

  ""
  " Reformat the current buffer with fish_indent or the binary named in
  " @flag(fish_indent_executable), only targeting the range between {startline}
  " and {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [ s:plugin.Flag('fish_indent_executable') ]
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    " fish_indent does not support range formatting yet:
    " https://github.com/fish-shell/fish-shell/issues/6490
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline, a:endline, l:cmd)
  endfunction

  return l:formatter
endfunction
