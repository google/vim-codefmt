" Copyright 2023 Google LLC
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

let s:checkedInstall = 0

""
" @private
" Formatter: JuliaFormatter
function! codefmt#juliaformatter#GetFormatter() abort
  let l:installer =
        \ maktaba#path#Join([s:plugin.location, 'bin', 'julia', 'install'])
  let l:formatter = {
        \ 'name': 'JuliaFormatter', 'setup_instructions': 'Run ' . l:installer}

  function l:formatter.IsAvailable() abort
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray('julia_format_executable')
    if codefmt#ShouldPerformIsAvailableChecks()
      if !executable(l:cmd[0])
       return 0
     endif
     if !s:checkedInstall
       let s:checkedInstall = 1
       let l:syscall = maktaba#syscall#Create([cmd[0], "--check-install"])
       call l:syscall.Call(0)
       if v:shell_error != 0
         return 0
       endif
     endif
    endif
    return 1
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'julia')
  endfunction

  ""
  " Reformat the current buffer using formatjulia.jl, only targeting {ranges}.
  function l:formatter.FormatRanges(ranges) abort
    if empty(a:ranges)
      return
    endif
    for [l:startline, l:endline] in a:ranges
      call maktaba#ensure#IsNumber(l:startline)
      call maktaba#ensure#IsNumber(l:endline)
    endfor
    let l:exec = s:plugin.Flag('julia_format_executable')
    if empty(l:exec)
      let l:cmd = [maktaba#path#Join(
            \ [s:plugin.location, 'bin', 'julia', 'formatjulia.jl'])]
    else
      " Split the command on spaces, unless preceeded by a backslash
      let l:cmd = split(l:exec, '\\\@<! ')
    endif
    " JuliaFormatter looks up .JuliaFormatter.toml settings based on file tree
    let l:cmd += ['--file-path', @%]
    let l:cmd += ['--lines']
    let l:cmd += maktaba#function#Map(a:ranges, {x -> x[0] . ':' . x[1]})
    call codefmt#formatterhelpers#Format(l:cmd)
  endfunction

  return l:formatter
endfunction
