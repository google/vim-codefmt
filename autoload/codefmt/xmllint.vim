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
"
" Formatter provider for Bazel BUILD files using xmllint.
function! codefmt#xmllint#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'xmllint',
      \ 'setup_instructions': 'Install xmllint. ' .
          \ '(man xmllint).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('xmllint_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'xml'
  endfunction

  ""
  " Reformat the current buffer with xmllint or the binary named in
  " @flag(xmllint)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('xmllint_executable'), '--format', '-' ]
    let l:input = join(getline(1, line('$')), "\n")
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    catch
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for line in split(v:exception, "\n")
        let l:tokens = matchlist(line, '\C\v^stdin:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ "filename": @%,
              \ "lnum": l:tokens[1],
              \ "col": l:tokens[2],
              \ "text": l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse xmllint error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
