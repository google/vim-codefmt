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

""
" @section Autocommands, autocmds
" You can enable automatic formatting on a buffer using
" @command(AutoFormatBuffer).

let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


""
" Automatically reformat when saving files.
augroup codefmt
  autocmd!
  autocmd BufWritePre * call s:FmtIfAutoEnabled()
augroup END

function! s:FmtIfAutoEnabled() abort
  if get(b:, 'codefmt_auto_format_buffer')
    call codefmt#FormatBuffer()
  endif
endfunction
