" Copyright 2017 Google Inc. All rights reserved.
" Copyright 2019 Jingrong Chen i@cjr.host
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
" Formatter provider for Bazel BUILD files using buildifier.
function! codefmt#hindent#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'hindent',
      \ 'setup_instructions': 'Install hindent. ' .
          \ '(https://github.com/chrisdone/hindent).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('hindent_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'haskell'
  endfunction

  ""
  " Reformat the current buffer with yapf or the binary named in
  " @flag(hindent_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:executable = s:plugin.Flag('hindent_executable')
	let l:indent_size = s:plugin.Flag('hindent_indent_size')
	let l:line_length = s:plugin.Flag('hindent_line_length')

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))

    let l:cmd = [l:executable, "--indent-size", l:indent_size, "--line-length", l:line_length]
	let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call(0)
    if v:shell_error == 1 " Indicates an error with parsing
      call maktaba#error#Shout('Error formatting file: %s', l:result.stderr)
      return
    endif
    let l:formatted = split(l:result.stdout, "\n")
	let l:before = a:startline > 1 ? l:lines[ : a:startline - 2 ] : []
	let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]

    call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
  endfunction

  return l:formatter
endfunction
