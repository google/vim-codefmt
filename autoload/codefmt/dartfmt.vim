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
" Formatter: dartfmt
function! codefmt#dartfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'dartfmt',
      \ 'setup_instructions': 'Install the Dart SDK from ' .
          \ 'https://dart.dev/get-dart'}

  function l:formatter.IsAvailable() abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'dartfmt_executable')
    if !empty(l:cmd) && executable(l:cmd[0])
      return 1
    else
      return 0
    endif
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'dart')
  endfunction

  ""
  " Reformat the current buffer with dart format or the binary named in
  " @flag(dartfmt_executable}, only targetting the range from {startline} to
  " {endline}
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'dartfmt_executable')
    try
      " dart format does not support range formatting yet:
      " https://github.com/dart-lang/dart_style/issues/92
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^line (\d+), column (\d+) of stdin: (.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse dartfmt error format; display it all.
        call maktaba#error#Shout(
            \ 'Failed to format range; showing all errors: %s', v:exception)
      else
        let l:errorHeaderLines = split(v:exception, "\n")[1 : 5]
        let l:errorHeader = join(l:errorHeaderLines, "\n")
        call maktaba#error#Shout(
            \ "Error formatting file:\n%s\n\nMore errors in the fixlist.",
            \ l:errorHeader)
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
