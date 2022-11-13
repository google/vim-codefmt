" Copyright 2021 Google Inc. All rights reserved.
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
" Formatter: ocamlformat
function! codefmt#ocamlformat#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ocamlformat',
      \ 'setup_instructions': 'Install ocamlformat ' .
          \ '(https://github.com/ocaml-ppx/ocamlformat#installation).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('ocamlformat_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'ocaml'
  endfunction

  ""
  " Reformat the current buffer with ocamlformat or the binary named in
  " @flag(ocamlformat_executable)
  " @throws ShellError
  "
  " We implement Format(), and not FormatRange{,s}(), because black doesn't
  " provide a hook for formatting a range
  function l:formatter.Format() abort
    let l:executable = s:plugin.Flag('ocamlformat_executable')

    " ocamlformat requires --name, --impl, or --intf when reading from
    " stdin.
    let l:inputflags = ['--name', @%]
    if len(@%) == 0
      " Assume we're formatting an implementation file.
      let l:inputflags = ['--impl']
    endif
    call codefmt#formatterhelpers#Format(
        \ [l:executable]
        \ + l:inputflags
        \ + ['-'])
  endfunction

  return l:formatter
endfunction
