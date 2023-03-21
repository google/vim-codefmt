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


""
" @private
" Formatter: black
function! codefmt#black#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'black',
      \ 'setup_instructions': 'Install black ' .
          \ '(https://pypi.python.org/pypi/black/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('black_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'python')
  endfunction

  ""
  " Reformat the current buffer with black or the binary named in
  " @flag(black_executable)
  "
  " We implement Format(), and not FormatRange{,s}(), because black doesn't
  " provide a hook for formatting a range
  function l:formatter.Format() abort
    let l:executable = s:plugin.Flag('black_executable')

    call codefmt#formatterhelpers#Format([
        \ l:executable,
        \ '-'])
  endfunction

  return l:formatter
endfunction
