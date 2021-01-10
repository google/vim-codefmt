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
" Formatter: rubocop
function! codefmt#rubocop#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'rubocop',
      \ 'setup_instructions': 'Install rubocop ' .
          \ '(https://rubygems.org/gems/rubocop).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('rubocop_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'eruby' || &filetype is# 'ruby'
  endfunction

  ""
  " Reformat the current buffer with rubocop or the binary named in
  " @flag(rubocop_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [s:plugin.Flag('rubocop_executable'), '--stdin', @%, '-a', '--no-color', '-fq', '-o', '/dev/null']

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")

    let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
    let l:full_formatted = l:before + l:formatted[1:] + l:lines[a:endline :]

    call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
  endfunction

  return l:formatter
endfunction

