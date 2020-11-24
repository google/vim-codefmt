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
" Formatter: ocamlformat
function! codefmt#ocamlformat#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ocamlformat',
      \ 'setup_instructions': 'Install ocamlformat' .
          \ '(https://github.com/ocaml-ppx/ocamlformat)'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('ocamlformat_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'ocaml'
  endfunction

  ""
  " Reformat the current buffer with ocamlformat or the binary named in
  " @flag(ocamlformat_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [ s:plugin.Flag('ocamlformat_executable'), '-' ]
    let l:fname = expand('%:p')
    if !empty(l:fname)
      let l:cmd += ['--name', l:fname]
      let l:fname_pattern = '"' . escape(l:fname, '\') . '"'
    else
      " assume it's an OCaml implementation file (.ml) if no file name is
      " provided
      let l:cmd += ['--impl']
      let l:fname_pattern = '\<standard input\>'
    end
    try
      " NOTE: ocamlformat does not support range formatting.
      " See https://github.com/ocaml-ppx/ocamlformat/pull/1188
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      let l:matchidx = 1
      while 1
        let l:tokens = matchlist(v:exception,
            \ '\vFile ' . l:fname_pattern . ', line (\d+), characters (\d+)-\d+:\n(.*)\n', 0, l:matchidx)
        if empty(l:tokens)
          break
        endif
        call add(l:errors, {
            \ 'filename': @%,
            \ 'lnum': l:tokens[1] + a:startline - 1,
            \ 'col': l:tokens[2],
            \ 'text': l:tokens[3]})
        let l:matchidx = l:matchidx + 1
      endwhile

      if empty(l:errors)
        " Couldn't parse ocamlformat error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
