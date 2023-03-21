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
" Invalidates the cached autopep8 version detection info.
function! codefmt#autopep8#InvalidateVersion() abort
  unlet! s:autopep8_supports_range
endfunction


""
" @private
" Formatter: autopep8
function! codefmt#autopep8#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'autopep8',
      \ 'setup_instructions': 'Install autopep8 ' .
          \ '(https://pypi.python.org/pypi/autopep8/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('autopep8_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'python')
  endfunction

  ""
  " Reformat the current buffer with autopep8 or the binary named in
  " @flag(autopep8_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:executable = s:plugin.Flag('autopep8_executable')
    if !exists('s:autopep8_supports_range')
      let l:version_call =
          \ maktaba#syscall#Create([l:executable, '--version']).Call()
      " In some cases version is written to stderr, in some to stdout
      let l:version_output = empty(version_call.stderr) ?
          \ version_call.stdout : version_call.stderr
      let l:autopep8_version =
          \ matchlist(l:version_output, '\m\Cautopep8 \(\d\+\)\.')
      if empty(l:autopep8_version)
        throw maktaba#error#Failure(
            \ 'Unable to parse version from `%s --version`: %s',
            \ l:executable, l:version_output)
      else
        let s:autopep8_supports_range = l:autopep8_version[1] >= 1
      endif
    endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    if s:autopep8_supports_range
      call codefmt#formatterhelpers#Format([
          \ l:executable,
          \ '--range', string(a:startline), string(a:endline),
          \ '-'])
    else
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline,
          \ a:endline,
          \ [l:executable, '-'])
    endif
  endfunction

  return l:formatter
endfunction
