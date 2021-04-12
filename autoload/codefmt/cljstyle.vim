" Copyright 2019 Google Inc. All rights reserved.
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
" Formatter: cljstyle
function! codefmt#cljstyle#GetFormatter() abort
  let l:formatter = {
        \ 'name': 'cljstyle',
        \ 'setup_instructions':
        \ 'Install cljstyle (https://github.com/greglook/cljstyle) ' .
        \ 'and configure the cljstyle_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('cljstyle_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'clojure'
  endfunction

  ""
  " Reformat the current buffer with cljstyle.
  "
  " We implement Format(), and not FormatRange{,s}(), because cljstyle doesn't
  " provide a hook for formatting a range
  function l:formatter.Format() abort
    let l:cmd = [s:plugin.Flag('cljstyle_executable'), 'pipe']

    call codefmt#formatterhelpers#Format(l:cmd)
  endfunction

  return l:formatter
endfunction
