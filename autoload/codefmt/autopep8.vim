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
    return &filetype is# 'python'
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
    let l:lines = getline(1, line('$'))

    if s:autopep8_supports_range
      let l:cmd = [l:executable, '--range', ''.a:startline, ''.a:endline, '-']
      let l:input = join(l:lines, "\n")
    else
      let l:cmd = [l:executable, '-']
      " Hack range formatting by formatting range individually, ignoring context.
      let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")
    endif

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")

    if s:autopep8_supports_range
      let l:full_formatted = l:formatted
    else
      " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
      let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
      let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]
    endif

    call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
  endfunction

  return l:formatter
endfunction
