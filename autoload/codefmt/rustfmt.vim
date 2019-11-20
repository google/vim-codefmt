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


""
" @private
" Formatter: rustfmt
function! codefmt#rustfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'rustfmt',
      \ 'setup_instructions': 'Install ' .
          \ 'rustfmt (https://github.com/rust-lang/rustfmt) ' .
          \ 'and configure the rustfmt_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('rustfmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'rust'
  endfunction

  ""
  " Reformat the current buffer with rustfmt or the binary named in
  " @flag(rustfmt_executable).
  function l:formatter.FormatRange(startline, endline) abort
    let l:Rustfmt_options = s:plugin.Flag('rustfmt_options')
    if type(l:Rustfmt_options) is# type([])
      let l:rustfmt_options = l:Rustfmt_options
    elseif maktaba#value#IsCallable(l:Rustfmt_options)
      let l:rustfmt_options = maktaba#function#Call(l:Rustfmt_options)
    else
      throw maktaba#error#WrongType(
          \ 'rustfmt_options flag must be list or callable. Found %s',
          \ string(l:Rustfmt_options))
    endif
    let l:cmd = [s:plugin.Flag('rustfmt_executable'), '--emit=stdout', '--color=never']

    call extend(l:cmd, l:rustfmt_options)
    try
      let l:lines = getline(1, line('$'))
      let l:input = join(l:lines, "\n")
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      " Even though rustfmt supports formatting ranges through the --file-lines
      " flag, it is not still enabled in the stable binaries.
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      let l:last_error_text = ''
      for l:line in split(v:exception, "\n")
        let l:error_text_tokens = matchlist(l:line,
            \ '\C\v^error: (.*)')
        if !empty(l:error_text_tokens)
          let l:last_error_text = l:error_text_tokens[1]
        endif

        let l:tokens = matchlist(l:line,
            \ '\C\v^.*\<stdin\>:(\d+):(\d+).*')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1],
              \ 'col': l:tokens[2],
              \ 'text': l:last_error_text})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse rustfmt error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
