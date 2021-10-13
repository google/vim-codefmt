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

let s:cmdAvailable = {}

""
" @private
" Formatter: ktfmt
function! codefmt#ktfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'ktfmt',
      \ 'setup_instructions': 'Install ktfmt ' .
          \ '(https://github.com/facebookincubator/ktfmt). ' .
          \ "Enable with\nGlaive codefmt ktfmt_executable=" .
          \ 'java,-jar,/path/to/ktfmt-<VERSION>-jar-with-dependencies.jar ' .
          \ "\nin your .vimrc or create a shell script named 'ktfmt'" }

  function l:formatter.IsAvailable() abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray('ktfmt_executable')
    if empty(l:cmd)
      return 0
    endif
    let l:joined = join(l:cmd, ' ')
    if has_key(s:cmdAvailable, l:joined)
      return s:cmdAvailable[l:joined]
    endif
    if executable(l:cmd[0])
      if l:cmd[0] is# 'java' || l:cmd[0] =~# '/java$'
        " Even if java is executable, jar path might be wrong, so run a simple
        " command. There's no --version flag, so format an empty file.
        let l:success = 0
        try
          let l:result = maktaba#syscall#Create(l:cmd + ['-']).Call()
          let l:success = v:shell_error != 0
        catch /ERROR(ShellError)/
          call maktaba#error#Shout(
                \ 'ktfmt unavailable, check jar file in %s -: %s',
                \ l:joined,
                \ v:exception)
        endtry
        let s:cmdAvailable[l:joined] = l:success
      else
        " command is executable and doesn't look like 'java' so assume yes
        let s:cmdAvailable[l:joined] = 1
      endif
    else
      if l:cmd[0] =~# ','
        call maktaba#error#Warn(
              \ 'ktfmt_executable is a string "%s" but looks like a list. '
              \ . 'Try not quoting the comma-separated value',
              \ l:cmd[0])
      endif
      return s:cmdAvailable[l:joined]
      " don't cache unavailability, in case user installs the command
      return 0
    endif
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'kotlin'
  endfunction

  ""
  " Reformat the current buffer using ktfmt, only targeting {ranges}.
  function l:formatter.FormatRange(startline, endline) abort
    " ktfmt requires '-' as a filename arg to read stdin
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray('ktfmt_executable')
          \ + ['-']
    try
      " TODO(tstone) Switch to using --lines once that arg is added, see
      " https://github.com/facebookincubator/ktfmt/issues/218
      call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
          \ a:startline, a:endline, l:cmd)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line, '\C\v^<stdin>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor
      if empty(l:errors)
        " Couldn't parse ktfmt error format; display it all.
        call maktaba#error#Shout('Error formatting range: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction


