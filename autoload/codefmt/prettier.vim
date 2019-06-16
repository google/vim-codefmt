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
" Formatter: prettier
function! codefmt#prettier#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'prettier',
      \ 'setup_instructions': 'Install prettier (https://prettier.io/) ' .
          \ 'and configure the prettier_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('prettier_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return index(s:supported_filetypes, &filetype) >= 0
  endfunction

  ""
  " Reformat the current buffer with prettier or the binary named in
  " @flag(prettier_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:Prettier_options = s:plugin.Flag('prettier_options')
    if type(l:Prettier_options) is# type([])
      let l:prettier_options = l:Prettier_options
    elseif maktaba#value#IsCallable(l:Prettier_options)
      let l:prettier_options = maktaba#function#Call(l:Prettier_options)
    else
      throw maktaba#error#WrongType(
          \ 'prettier_options flag must be list or callable. Found %s',
          \ string(l:Prettier_options))
    endif
    let l:cmd = [s:plugin.Flag('prettier_executable'), '--stdin', '--no-color']

    " prettier is able to automatically choose the best parser if the filepath
    " is provided. Otherwise, fall back to the previous default: babylon.
    if @% == ""
      call extend(l:cmd, ['--parser', 'babylon'])
    else
      call extend(l:cmd, ['--stdin-filepath', @%])
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

    call extend(l:cmd, l:prettier_options)
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
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
