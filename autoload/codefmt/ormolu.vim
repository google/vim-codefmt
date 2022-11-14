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
" Formatter: ormolu
function! codefmt#ormolu#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ormolu',
      \ 'setup_instructions': 'Install ormolu ' .
          \ '(https://hackage.haskell.org/package/ormolu).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('ormolu_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'haskell'
  endfunction

  ""
  " Reformat the current buffer with ormolu or the binary named in
  " @flag(ormolu_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [s:plugin.Flag('ormolu_executable')]

    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines, "\n")

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    if a:startline > 1
      call extend(l:cmd, ['--start-line', string(a:startline)])
    endif
    call extend(l:cmd, ['--end-line', string(a:endline)])

    try
      let l:syscall = maktaba#syscall#Create(l:cmd).WithStdin(l:input)
      let l:result = l:syscall.Call()
      let l:formatted = split(l:result.stdout, "\n")
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    catch /ERROR(ShellError):/
      call maktaba#error#Shout('Error formatting file: %s', v:exception)
    endtry
  endfunction

  return l:formatter
endfunction
