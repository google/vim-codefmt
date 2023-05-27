" Copyright 2023 Google Inc. All rights reserved.
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
" Formatter: rubocop
function! codefmt#rubocop#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'rubocop',
      \ 'setup_instructions': 'Install rubocop ' .
          \ '(https://rubygems.org/gems/rubocop).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('rubocop_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'eruby' || &filetype is# 'ruby'
  endfunction

  ""
  " Reformat the current buffer with rubocop or the binary named in
  " @flag(rubocop_executable), only targeting the range between {startline} and
  " {endline}.
  "
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    " See flag explanations at:
    " https://docs.rubocop.org/rubocop/1.51/usage/basic_usage.html
    let l:cmd = [s:plugin.Flag('rubocop_executable'), '--stdin', @%, '-a', '--no-color', '-fq', '-o', '/dev/null']

    " Rubocop exits with an error condition if there are lint errors, even
    " after successfully formatting. This is annoying for our purpuoses,
    " because we have no way to distinguish lint errors from a 'real' falure.
    " Use Call(0) to suppress maktaba's error handling.
    let l:ignoreerrors = 1
    " Rubocop is primarily a linter, and by default it outputs lint errors 
    " first, followed  by a dividing line, and then the formatted result.
    " '-o /dev/null' in the command line suppresses any lint errors, but the
    " divider is always printed.
    let l:skipfirstnlines = 1

    " Rubocop does not support range formatting; see bug:
    " https://github.com/Shopify/ruby-lsp/issues/203
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline, a:endline, l:cmd, l:ignoreerrors, l:skipfirstnlines)
  endfunction

  return l:formatter
endfunction
