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


function! s:FormatWithArgs(args) abort
  let l:executable = s:plugin.Flag('ruff_executable')
  let l:lines = getline(1, line('$'))
  let l:cmd = [l:executable, 'format'] + a:args
  if !empty(@%)
    let l:cmd += ['--stdin-filename=' . @%]
  endif
  let l:input = join(l:lines, "\n")
  let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call(0)
  if v:shell_error
    call maktaba#error#Shout('Error formatting file: %s', l:result.stderr)
    return
  endif
  let l:formatted = split(l:result.stdout, "\n")

  call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
endfunction


""
" @private
" Formatter: ruff
function! codefmt#ruff#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ruff',
      \ 'setup_instructions': 'Install ruff ' .
          \ '(https://docs.astral.sh/ruff/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('ruff_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'python')
  endfunction

  function l:formatter.Format() abort
    call s:FormatWithArgs([])
  endfunction

  ""
  " Reformat the current buffer with ruff or the binary named in
  " @flag(ruff_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    call s:FormatWithArgs(['--range=' . a:startline . ':' . a:endline])
  endfunction

  return l:formatter
endfunction
