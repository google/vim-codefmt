" Copyright 2025 Google Inc. All rights reserved.
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
" Formatter: terraform-fmt
function! codefmt#terraformfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'terraform-fmt',
      \ 'setup_instructions': 'Install terraform and ' .
          \ 'configure the terraform_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('terraform_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'terraform') ||
        \ codefmt#formatterhelpers#FiletypeMatches(&filetype, 'hcl')
  endfunction

  ""
  " Reformat the current buffer with terraform fmt or the binary named in
  " @flag(terraform_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [ s:plugin.Flag('terraform_executable'), 'fmt', '-' ]
    try
      " terraform fmt does not support range formatting.
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        " terraform fmt error format:
        " Error: <standard input>:1,13-14: Argument or block definition required; ...
        " Or sometimes different.
        let l:tokens = matchlist(l:line,
            \ '\C\v^\s*Error: \<standard input\>:\(\d+\),(\d+)-(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[4]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse terraform error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
