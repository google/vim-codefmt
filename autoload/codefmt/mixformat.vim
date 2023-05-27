" Copyright 2022 Google Inc. All rights reserved.
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
let s:cmdAvailable = {}

""
" @private
" Formatter: mixformat
function! codefmt#mixformat#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'mixformat',
      \ 'setup_instructions': 'mix is usually installed with Elixir ' .
          \ '(https://elixir-lang.org/install.html). ' .
          \ "If mix is not in your path, configure it in .vimrc:\n" .
          \ 'Glaive codefmt mix_executable=/path/to/mix' }

  function l:formatter.IsAvailable() abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray('mix_executable')
    if codefmt#ShouldPerformIsAvailableChecks() && !executable(l:cmd[0])
      return 0
    endif
    return 1
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(
        \ &filetype, ['elixir', 'eelixir', 'heex'])
  endfunction

  ""
  " Reformat the current buffer using mix format, only targeting {ranges}.
  function l:formatter.FormatRange(startline, endline) abort
    let l:filename = expand('%:p')
    if empty(l:filename)
      let l:dir = getcwd()
      " Default filename per https://hexdocs.pm/mix/Mix.Tasks.Format.html
      let l:filename = 'stdin.exs'
    else
      let l:dir = s:findMixDir(l:filename)
    endif
    " mix format docs: https://hexdocs.pm/mix/main/Mix.Tasks.Format.html
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray('mix_executable')
    " Specify stdin as the file
    let l:cmd = l:cmd + ['format', '--stdin-filename=' . l:filename, '-']
    let l:syscall = maktaba#syscall#Create(l:cmd).WithCwd(l:dir)
    try
      " mix format doesn't have a line-range option, but does a reasonable job
      " (except for leading indent) when given a full valid expression
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:syscall)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        " Example output:
        " ** (SyntaxError) foo.exs:57:28: unexpected reserved word: end
        " (blank line)
        "     HINT: it looks like the "end" on line 56 does not have a matching "do" defined before it
        " (blank line), (stack trace with 4-space indent)
        " TODO gather additional details between error message and stack trace
        let l:tokens = matchlist(l:line,
              \ printf('\v^\*\* (\(\k+\)) [^:]+:(\d+):(\d+):\s*(.*)'))
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[2] + a:startline - 1,
              \ 'col': l:tokens[3],
              \ 'text': printf('%s %s', l:tokens[1], l:tokens[4])})
        endif
      endfor
      if empty(l:errors)
        " Couldn't parse mix error format; display it all.
        call maktaba#error#Shout('Error formatting range: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction

" Finds the directory to run mix from.  Looks for a mix.exs file first; if that
" is not found looks for a .formatter.exs file, falling back to the parent of
" filepath.
function! s:findMixDir(filepath) abort
  let l:path = empty(a:filepath) ? getcwd() : fnamemodify(a:filepath, ':h')
  let l:root = findfile('mix.exs', l:path . ';')
  if empty(l:root)
    let l:root = findfile('.formatter.exs', l:path . ';')
  endif
  if empty(l:root)
    let l:root = l:path
  else
    let l:root = fnamemodify(l:root, ':h')
  endif
  return l:root
endfunction
