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
" Formatter: cmake-format
function! codefmt#cmakeformat#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'cmake-format',
      \ 'setup_instructions': 'Install cmake-format from ' .
          \ 'https://cmake-format.readthedocs.io/en/latest/installation.html ' .
          \ 'and configure the cmake_format_executable, ' .
          \ 'cmake_format_config flags'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('cmake_format_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    if &filetype is# 'cmake'
      return 1
    endif
  endfunction

  ""
  " Reformat buffer with cmake-format.
  "
  " Implements format(), and not formatrange{,s}(), because cmake-format
  " doesn't provide a hook for formatting a range, and cmake files are
  " supposed to be fully formatted anyway.
  function l:formatter.Format() abort
    let l:cmd = [s:plugin.Flag('cmake_format_executable')]

    " Append configuration style.
    let l:config = s:plugin.Flag('cmake_format_config')
    if !empty(l:config)
        if type(l:config) is# type('')
          let l:cmd += ['-c', l:config]
        else
          throw maktaba#error#WrongType(
              \ 'cmake_format_config flag must be string. Found' 
              \ , string(l:config))
        endif
    endif

    " Append filename.
    let l:fname = expand('%:p')
    if empty(l:fname)
        return
    endif
    let l:cmd += [l:fname]

    " Generate formatted output.
    let l:input = join(getline(1, line('$')), "\n")
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")

    " Overwrite buffer.
    call maktaba#buffer#Overwrite(1, line('$'), l:formatted[0:])
  endfunction

  return l:formatter
endfunction
