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
" Formatter for gn, a chromium build tool.
" Formatter: gn
function! codefmt#gn#GetFormatter() abort
  let l:url = 'https://www.chromium.org/developers/how-tos/install-depot-tools'
  let l:formatter = {
        \ 'name': 'gn',
        \ 'setup_instructions': 'install Chromium depot_tools (' . l:url . ')'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('gn_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'gn'
  endfunction

  ""
  " Run `gn format` to format the whole file.
  "
  " We implement Format(), and not FormatRange{,s}(), because gn doesn't
  " provide a hook for formatting a range, and all gn files are supposed
  " to be fully formatted anyway.
  function l:formatter.Format() abort
    let l:executable = s:plugin.Flag('gn_executable')
    let l:cmd = [ l:executable, 'format', '--stdin' ]
    let l:input = join(getline(1, line('$')), "\n")

    " gn itself prints errors to stdout, but if the error comes from the
    " gn.py wrapper script, it is printed to stderr. Use stdout as the
    " error message if stderr is empty.
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call(0)
    if !empty(l:result.stdout)
      let l:output = l:result.stdout
    else
      let l:output = l:result.stderr
    endif

    " Other formatters generally catch failure as an exception, but
    " v:exception contains stderr in that case, and gn prints errors to
    " stdout, so we need to check for a shell error ourselves.
    if !v:shell_error
      let l:formatted = split(l:output, "\n")
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    else
      let l:errors = []
      for line in split(l:output, "\n")
        let l:tokens = matchlist(line, '\C\v^ERROR at :(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
                \ "filename": @%,
                \ "lnum": l:tokens[1],
                \ "col": l:tokens[2],
                \ "text": l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse errors; display the whole error message.
        call maktaba#error#Shout('Error formatting file: %s', l:output)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endif
  endfunction

  return l:formatter
endfunction
