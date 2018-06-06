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


function! s:ClangFormatHasAtLeastVersion(minimum_version) abort
  if !exists('s:clang_format_version')
    let l:executable = s:plugin.Flag('clang_format_executable')
    if codefmt#ShouldPerformIsAvailableChecks() && !executable(l:executable)
      return 0
    endif

    let l:version_output =
          \ maktaba#syscall#Create([l:executable, '--version']).Call().stdout
    let l:version_string = matchstr(l:version_output, '\v\d+(.\d+)+')
    let s:clang_format_version = map(split(l:version_string, '\.'), 'v:val + 0')
  endif
  let l:length = min([len(a:minimum_version), len(s:clang_format_version)])
  for i in range(l:length)
    if a:minimum_version[i] < s:clang_format_version[i]
      return 1
    elseif a:minimum_version[i] > s:clang_format_version[i]
      return 0
    endif
  endfor
  return len(a:minimum_version) <= len(s:clang_format_version)
endfunction


""
" @private
" Invalidates the cached clang-format version.
function! codefmt#clangformat#InvalidateVersion() abort
  unlet! s:clang_format_version
endfunction


""
" @private
" Formatter: clang-format
function! codefmt#clangformat#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'clang-format',
      \ 'setup_instructions': 'Install clang-format from ' .
          \ 'http://clang.llvm.org/docs/ClangFormat.html and ' .
          \ 'configure the clang_format_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('clang_format_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    if &filetype is# 'c' || &filetype is# 'cpp' ||
        \ &filetype is# 'proto' || &filetype is# 'javascript' ||
        \ &filetype is# 'objc' || &filetype is# 'objcpp' ||
        \ &filetype is# 'typescript'
      return 1
    endif
    " Version 3.6 adds support for java
    " http://llvm.org/releases/3.6.0/tools/clang/docs/ReleaseNotes.html
    return &filetype is# 'java' && s:ClangFormatHasAtLeastVersion([3, 6])
  endfunction

  ""
  " Reformat buffer with clang-format, only targeting [ranges] if given.
  function l:formatter.FormatRanges(ranges) abort
    let l:Style_value = s:plugin.Flag('clang_format_style')
    if type(l:Style_value) is# type('')
      let l:style = l:Style_value
    elseif maktaba#value#IsCallable(l:Style_value)
      let l:style = maktaba#function#Call(l:Style_value)
    else
      throw maktaba#error#WrongType(
          \ 'clang_format_style flag must be string or callable. Found %s',
          \ string(l:Style_value))
    endif
    if empty(a:ranges)
      return
    endif

    let l:cmd = [
        \ s:plugin.Flag('clang_format_executable'),
        \ '-style', l:style]
    let l:fname = expand('%:p')
    if !empty(l:fname)
      let l:cmd += ['-assume-filename', l:fname]
    endif

    for [l:startline, l:endline] in a:ranges
      call maktaba#ensure#IsNumber(l:startline)
      call maktaba#ensure#IsNumber(l:endline)
      let l:cmd += ['-lines', l:startline . ':' . l:endline]
    endfor

    " Version 3.4 introduced support for cursor tracking
    " http://llvm.org/releases/3.4/tools/clang/docs/ClangFormat.html
    let l:supports_cursor = s:ClangFormatHasAtLeastVersion([3, 4])
    if l:supports_cursor
      " line2byte counts bytes from 1, and col counts from 1, so -2 
      let l:cursor_pos = line2byte(line('.')) + col('.') - 2
      let l:cmd += ['-cursor', string(l:cursor_pos)]
    endif

    let l:input = join(getline(1, line('$')), "\n")
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")

    if !l:supports_cursor
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted[0:])
    else
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted[1:])
      try
        let l:clang_format_output_json = maktaba#json#Parse(l:formatted[0])
        let l:new_cursor_pos =
            \ maktaba#ensure#IsNumber(l:clang_format_output_json.Cursor) + 1
        execute 'goto' l:new_cursor_pos
      catch
        call maktaba#error#Warn('Unable to parse clang-format cursor pos: %s',
            \ v:exception)
      endtry
    endif
  endfunction

  return l:formatter
endfunction
