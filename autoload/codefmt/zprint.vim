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

""
" @section Recommended zprint mappings, mappings-zprint
" @parentsection mappings
"
" Since zprint only works on top-level Clojure forms, it doesn't make sense to
" format line ranges that aren't complete forms. If you're using vim-sexp
" (https://github.com/guns/vim-sexp), the following mapping replaces the default
" "format the current line" with "format the current top-level form." >
"   autocmd FileType clojure nmap <buffer> <silent> <leader>== <leader>=iF
" <


let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
" Formatter: zprint
function! codefmt#zprint#GetFormatter() abort
  let l:formatter = {
        \ 'name': 'zprint',
        \ 'setup_instructions':
        \ 'Install zprint filter (https://github.com/kkinnear/zprint) ' .
        \ 'and configure the zprint_executable flag'}

  function l:formatter.IsAvailable() abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'zprint_executable')
    return !empty(l:cmd) && executable(l:cmd[0])
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'clojure'
  endfunction

  ""
  " Reformat the current buffer with zprint or the binary named in
  " @flag(zprint_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:exe = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'zprint_executable')
    let l:opts = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'zprint_options')

    " Prepare the syscall
    let l:syscall = maktaba#syscall#Create(l:exe + l:opts)
    if isdirectory(expand('%:p:h'))
      " Change to the containing directory in case the user has configured
      " {:search-config? true} in ~/.zprintrc
      let l:syscall = l:syscall.WithCwd(expand('%:p:h'))
    endif

    " zprint does not support range formatting yet:
    " https://github.com/kkinnear/zprint/issues/122
    " This fake range formatting works well for top-level forms, although it's
    " not ideal for inner forms because it loses the indentation.
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline,
        \ a:endline,
        \ l:syscall)
  endfunction

  return l:formatter
endfunction
