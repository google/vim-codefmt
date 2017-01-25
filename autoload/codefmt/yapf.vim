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
" Formatter: yapf
function! codefmt#yapf#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'yapf',
      \ 'setup_instructions': 'Install yapf ' .
          \ '(https://pypi.python.org/pypi/yapf/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('yapf_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'python'
  endfunction

  ""
  " Reformat the current buffer with yapf or the binary named in
  " @flag(yapf_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:executable = s:plugin.Flag('yapf_executable')

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))

    let l:cmd = [l:executable, '--lines=' . a:startline . '-' . a:endline]
    let l:input = join(l:lines, "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call(0)
    if v:shell_error == 1 " Indicates an error with parsing
      call maktaba#error#Shout('Error formatting file: %s', l:result.stderr)
      return
    endif
    let l:formatted = split(l:result.stdout, "\n")

    call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
  endfunction

  return l:formatter
endfunction
