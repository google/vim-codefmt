" Copyright 2014 Google Inc. All rights reserved.
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

let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Enables format on save for this buffer using [formatter].
" @default formatter=[first available for buffer] the formatter to use
function! s:AutoFormatBuffer(...) abort
  if a:0 == 1
    let b:codefmt_formatter = a:1
  endif
  let b:codefmt_auto_format_buffer = 1
endfunction

function! s:FormatLinesAndSetRepeat(startline, endline, ...) abort
  call call('codefmt#FormatLines', [a:startline, a:endline] + a:000)
  let l:cmd = ":FormatLines " . join(a:000, ' ') . "\<CR>"
  let l:lines_formatted = a:endline - a:startline + 1
  silent! call repeat#set(l:cmd, l:lines_formatted)
endfunction

function! s:FormatBufferAndSetRepeat(...) abort
  call call('codefmt#FormatBuffer', a:000)
  let l:cmd = ":FormatCode " . join(a:000, ' ') . "\<CR>"
  silent! call repeat#set(l:cmd)
endfunction

""
" Format the current line or range using [formatter].
" @default formatter=the default formatter associated with the current buffer
command -nargs=? -range -complete=custom,codefmt#GetSupportedFormatters
    \ FormatLines call s:FormatLinesAndSetRepeat(<line1>, <line2>, <f-args>)

""
" Format the whole buffer using [formatter].
" See @section(formatters) for list of valid formatters.
" @default formatter=the default formatter associated with the current buffer
command -nargs=? -complete=custom,codefmt#GetSupportedFormatters
    \ FormatCode call s:FormatBufferAndSetRepeat(<f-args>)

""
" Enables format on save for this buffer using [formatter]. Also configures
" [formatter] as the default formatter for this buffer via the
" @setting(b:codefmt_formatter) variable.
" @default formatter=the default formatter associated with the current buffer
command -nargs=? -complete=custom,codefmt#GetSupportedFormatters
    \ AutoFormatBuffer call s:AutoFormatBuffer(<f-args>)

""
" Disables format on save for this buffer.
command -nargs=0 NoAutoFormatBuffer let b:codefmt_auto_format_buffer = 0

