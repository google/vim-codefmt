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
" Formatter: google-java-format
function! codefmt#googlejava#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'google-java-format',
      \ 'setup_instructions': 'Install google-java formatter ' .
          \ "(https://github.com/google/google-java-format). \n" .
          \ 'Enable with "Glaive codefmt google_java_executable=' .
          \ '"java -jar /path/to/google-java-format-VERSION-all-deps.jar" ' .
          \ 'in your vimrc' }

  function l:formatter.IsAvailable() abort
    let l:exec = s:plugin.Flag('google_java_executable')
    if executable(l:exec)
      return 1
    elseif !empty(l:exec) && l:exec isnot# 'google-java-format'
      " The user has specified a custom formatter command. Hope it works.
      " /shrug.
      return 1
    else
      return 0
    endif
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'java'
  endfunction

  ""
  " Reformat the current buffer using java-format, only targeting {ranges}.
  function l:formatter.FormatRanges(ranges) abort
    if empty(a:ranges)
      return
    endif
    " Split the command on spaces, except when there's a proceeding \
    let l:cmd = split(s:plugin.Flag('google_java_executable'), '\\\@<! ')
    for [l:startline, l:endline] in a:ranges
      call maktaba#ensure#IsNumber(l:startline)
      call maktaba#ensure#IsNumber(l:endline)
    endfor
    let l:ranges_str = join(map(copy(a:ranges), 'v:val[0] . ":" . v:val[1]'), ',')
    let l:cmd += ['--lines', l:ranges_str, '-']

    let l:input = join(getline(1, line('$')), "\n")
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")
    call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
  endfunction

  return l:formatter
endfunction


