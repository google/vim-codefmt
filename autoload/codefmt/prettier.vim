" Copyright 2018 Google Inc. All rights reserved.
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

" See https://prettier.io for a list of supported file types.
let s:supported_filetypes = ['javascript', 'markdown', 'html', 'css', 'yaml',
      \ 'jsx', 'less', 'scss', 'mdx', 'vue']


""
" @private
" Invalidates the cached prettier availability detection.
function! codefmt#prettier#InvalidateIsAvailable() abort
  unlet! s:prettier_is_available
endfunction


""
" @private
" Formatter: prettier
function! codefmt#prettier#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'prettier',
      \ 'setup_instructions': 'Install prettier (https://prettier.io/) ' .
          \ 'and configure the prettier_executable flag'}

  function l:formatter.IsAvailable() abort
    if !exists('s:prettier_is_available')
      let s:prettier_is_available = 0
      let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
            \ 'prettier_executable')
      if !empty(l:cmd) && executable(l:cmd[0])
        " Unfortunately the availability of npx isn't enough to tell whether
        " prettier is available, and npx doesn't have a way of telling us.
        " Fetching the prettier version should suffice.
        let l:result = maktaba#syscall#Create(l:cmd + ['--version']).Call(0)
        if v:shell_error == 0
          let s:prettier_is_available = 1
        endif
      endif
    endif
    return s:prettier_is_available
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return index(s:supported_filetypes, &filetype) >= 0
  endfunction

  ""
  " Reformat the current buffer with prettier or the binary named in
  " @flag(prettier_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'prettier_executable') + ['--no-color']

    " prettier is able to automatically choose the best parser if the filepath
    " is provided. Otherwise, fall back to the previous default: babel.
    if @% == ""
      call extend(l:cmd, ['--parser', 'babel'])
    else
      call extend(l:cmd, ['--stdin-filepath', expand('%:p')])
    endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines, "\n")
    if a:startline > 1
      let l:lines_start = join(l:lines[0 : a:startline - 1], "\n")
      call extend(l:cmd, ['--range-start', string(strchars(l:lines_start))])
    endif
    let l:lines_end = join(l:lines[0 : a:endline - 1], "\n")
    call extend(l:cmd, ['--range-end', string(strchars(l:lines_end))])

    call extend(l:cmd, codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'prettier_options'))

    try
      let l:syscall = maktaba#syscall#Create(l:cmd).WithStdin(l:input)
      if isdirectory(expand('%:p:h'))
        " Change to the containing directory so that npx will find
        " a project-local prettier in node_modules
        let l:syscall = l:syscall.WithCwd(expand('%:p:h'))
      endif
      let l:result = l:syscall.Call()
      let l:formatted = split(l:result.stdout, "\n")
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^\[error\] stdin: (.*) \((\d+):(\d+)\).*')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[2],
              \ 'col': l:tokens[3],
              \ 'text': l:tokens[1]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse prettier error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
