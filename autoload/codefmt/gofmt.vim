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
    " Hack range formatting by formatting range individually, ignoring context.
    let l:cmd = [ s:plugin.Flag('gofmt_executable') ]
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
      let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []

      let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]
      call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
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
