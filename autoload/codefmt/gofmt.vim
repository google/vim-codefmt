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
" Formatter: gofmt
function! codefmt#gofmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'gofmt',
      \ 'setup_instructions': 'Install gofmt or goimports and ' .
          \ 'configure the gofmt_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('gofmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'go'
  endfunction

  ""
  " Reformat the current buffer with gofmt or the binary named in
  " @flag(gofmt_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [ s:plugin.Flag('gofmt_executable') ]
    try
      " gofmt does not support range formatting.
      " TODO: File a feature request with gofmt and link it here.
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^\<standard input\>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse gofmt error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
