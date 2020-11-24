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


let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
"
" Formatter provider for .nix files using nixpkgs-fmt.
function! codefmt#nixpkgs_fmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'nixpkgs-fmt',
      \ 'setup_instructions': 'Install nixpkgs-fmt. ' .
          \ '(https://github.com/nix-community/nixpkgs-fmt).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('nixpkgs_fmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'nix'
  endfunction

  ""
  " Reformat the current buffer with nixpkgs-fmt or the binary named in
  " @flag(nixpkgs_fmt_executable)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('nixpkgs_fmt_executable') ]

    " nixpkgs-fmt does not support range formatting.
    call codefmt#formatterhelpers#Format(l:cmd)
  endfunction

  return l:formatter
endfunction
