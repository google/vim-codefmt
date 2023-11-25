" Copyright 2023 Google Inc. All rights reserved.
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
" Formatter: perltidy
function! codefmt#perltidy#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'perltidy',
      \ 'setup_instructions': 'Install perltidy ' .
          \ '(https://perltidy.sourceforge.net/INSTALL.html).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('perltidy_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'perl')
  endfunction

  ""
  " Reformat the current buffer with perltidy or the binary named in
  " @flag(perltidy_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:executable = s:plugin.Flag('perltidy_executable')

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    " Perltidy does not support range formatting.
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline,
        \ a:endline,
        \ [l:executable, '-'])
  endfunction

  return l:formatter
endfunction
