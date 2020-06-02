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
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'clang_format_executable')
    if codefmt#ShouldPerformIsAvailableChecks() && !executable(l:cmd[0])
      return 0
    endif

    let l:syscall = maktaba#syscall#Create(l:cmd + ['--version'])
    " Call with throw_errors disabled because some versions of clang-format
    " misbehave and return exit code 1 along with the successful version
    " output (see https://github.com/google/vim-codefmt/issues/84).
    let l:version_output = l:syscall.Call(0).stdout
    let l:version_string = matchstr(l:version_output, '\v\d+(.\d+)+')
    " If no version string was matched, cached version will be an empty list.
    let s:clang_format_version = map(split(l:version_string, '\.'), 'v:val + 0')
  endif
  " Always fail check if version couldn't be fetched.
  if empty(s:clang_format_version)
    return 0
  endif
  " Compare each dotted version value in turn.
  let l:length = max([len(a:minimum_version), len(s:clang_format_version)])
  for i in range(l:length)
    " Consider missing version places as zero (e.g. 7 = 7.0 = 7.0.0).
    let l:detected_value = get(s:clang_format_version, i, 0)
    let l:minimum_value = get(a:minimum_version, i, 0)
    " Any place value above or below than its minimum means entire version is
    " above or below the minimum.
    if l:detected_value > l:minimum_value
      return 1
    elseif l:detected_value < l:minimum_value
      return 0
    endif
  endfor
  " All version numbers were equal, so version was at least minimum.
  return 1
endfunction


" Inputs are 1-based (row, col) coordinates into lines.
" Returns the corresponding zero-based offset into lines->join("\n")
function! s:PositionToOffset(row, col, lines) abort
  let l:offset = a:col - 1 " 1-based to 0-based
  if a:row > 1
    for l:line in a:lines[0 : a:row - 2] " 1-based to 0-based, exclude current
      let l:offset += len(l:line) + 1 " +1 for newline
    endfor
  endif
  return l:offset
endfunction


" Input is zero-based offset into lines->join("\n")
" Returns the 1-based [row, col] coordinates into lines.
function! s:OffsetToPosition(offset, lines) abort
  let l:lines_consumed = 0
  let l:chars_left = a:offset
  for l:line in a:lines
    let l:line_len = len(l:line) + 1 " +1 for newline
    if l:chars_left < l:line_len
      break
    endif
    let l:chars_left -= l:line_len
    let l:lines_consumed += 1
  endfor
  return [l:lines_consumed + 1, l:chars_left + 1] " 0-based to 1-based
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
    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'clang_format_executable')
    if !empty(l:cmd) && executable(l:cmd[0])
      return 1
    else
      return 0
    endif
  endfunction

  function l:formatter.AppliesToBuffer() abort
    if &filetype is# 'c' || &filetype is# 'cpp' ||
        \ &filetype is# 'proto' || &filetype is# 'javascript' ||
        \ &filetype is# 'objc' || &filetype is# 'objcpp' ||
        \ &filetype is# 'typescript' || &filetype is# 'arduino'
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

    let l:cmd = codefmt#formatterhelpers#ResolveFlagToArray(
          \ 'clang_format_executable') + ['-style', l:style]
    let l:fname = expand('%:p')
    if !empty(l:fname)
      let l:cmd += ['-assume-filename', l:fname]
    endif

    for [l:startline, l:endline] in a:ranges
      call maktaba#ensure#IsNumber(l:startline)
      call maktaba#ensure#IsNumber(l:endline)
      let l:cmd += ['-lines', l:startline . ':' . l:endline]
    endfor

    let l:lines = getline(1, line('$'))

    " Version 3.4 introduced support for cursor tracking
    " http://llvm.org/releases/3.4/tools/clang/docs/ClangFormat.html
    let l:supports_cursor = s:ClangFormatHasAtLeastVersion([3, 4])
    if l:supports_cursor
      " Avoid line2byte: https://github.com/vim/vim/issues/5930
      let l:cursor_pos = s:PositionToOffset(line('.'), col('.'), l:lines)
      let l:cmd += ['-cursor', string(l:cursor_pos)]
    endif

    let l:input = join(l:lines, "\n")
    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")

    if l:supports_cursor
      " With -cursor, the first line is a JSON object.
      let l:header = remove(l:formatted, 0)
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
      try
        let l:header_json = maktaba#json#Parse(l:header)
        let l:offset = maktaba#ensure#IsNumber(l:header_json.Cursor)
        " Compute line/col, avoid goto: https://github.com/vim/vim/issues/5930
        let [l:new_line, l:new_col] = s:OffsetToPosition(l:offset, l:formatted)
        call cursor(l:new_line, l:new_col)
      catch
        call maktaba#error#Warn('Unable to parse clang-format cursor pos: %s',
            \ v:exception)
      endtry
    else
      call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
    endif
  endfunction

  return l:formatter
endfunction
