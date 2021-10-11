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
" Formatter: ktfmt
function! codefmt#ktfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ktfmt',
      \ 'setup_instructions': 'Install ktfmt ' .
          \ "(https://github.com/facebookincubator/ktfmt).\n" .
          \ 'Enable with "Glaive codefmt ktfmt_executable=' .
          \ '"java -jar /path/to/ktfmt-<VERSION>-jar-with-dependencies.jar" ' .
          \ 'in your .vimrc' }

  function l:formatter.IsAvailable() abort
    let l:exec = split(s:plugin.Flag('ktfmt_executable'), '\\\@<! ')
    if empty(l:exec)
      return 0
    endif
    if executable(l:exec[0])
      return 1
    elseif !empty(l:exec[0]) && l:exec[0] isnot# 'ktfmt'
      " The user has specified a custom formatter command. Hope it works.
      return 1
    else
      return 0
    endif
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'kotlin'
  endfunction

  ""
  " Reformat the current buffer using ktfmt, only targeting {ranges}.
  function l:formatter.FormatRange(startline, endline) abort
    " Split the command on spaces, except when there's a proceeding \
    let l:cmd = split(s:plugin.Flag('ktfmt_executable'), '\\\@<! ')
    " ktfmt requires '-' as a filename arg to read stdin
    let l:cmd = add(l:cmd, '-')
    try
      " TODO(tstone) Switch to using --lines once that arg is added, see
      " https://github.com/facebookincubator/ktfmt/issues/218
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line, '\C\v^<stdin>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor
      if empty(l:errors)
        " Couldn't parse ktfmt error format; display it all.
        call maktaba#error#Shout('Error formatting range: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction


