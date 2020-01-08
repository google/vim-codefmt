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
" Formatter: js-beautify
function! codefmt#jsbeautify#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'js-beautify',
      \ 'setup_instructions': 'Install js-beautify ' .
          \ '(https://www.npmjs.com/package/js-beautify).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('js_beautify_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'css' || &filetype is# 'html' || &filetype is# 'json' ||
        \ &filetype is# 'javascript'
  endfunction

  ""
  " Reformat the current buffer with js-beautify or the binary named in
  " @flag(js_beautify_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [s:plugin.Flag('js_beautify_executable'), '-f', '-']
    if &filetype is# 'javascript' || &filetype is# 'json'
      let l:cmd = l:cmd + ['--type', 'js']
    elseif &filetype is# 'sass' || &filetype is# 'scss' || &filetype is# 'less'
      let l:cmd = l:cmd + ['--type', 'css']
    elseif &filetype != ""
      let l:cmd = l:cmd + ['--type', &filetype]
    endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    " js-beautify does not support range formatting yet:
    " https://github.com/beautify-web/js-beautify/issues/610
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline, a:endline, l:cmd)
  endfunction

  return l:formatter
endfunction

