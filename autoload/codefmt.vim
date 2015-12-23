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
" @section Formatters, formatters
" This plugin has three built-in formatters: clang-format, gofmt, and autopep8.
" More formatters can be registered by other plugins that integrate with
" codefmt.
"
" @subsection Default formatters
" Codefmt will automatically use a default formatter for certain filetypes if
" none is explicitly supplied via an explicit arg to @command(FormatCode) or the
" @setting(b:codefmt_formatter) variable. The default formatter may also depend
" on what plugins are enabled or what other software is installed on your
" system.
"
" The current list of defaults by filetype is:
"   * c, cpp, proto, javascript: clang-format
"   * go: gofmt
"   * python: autopep8, yapf


let s:plugin = maktaba#plugin#Get('codefmt')
let s:registry = s:plugin.GetExtensionRegistry()


""
" @dict Formatter
" Interface for applying formatting to lines of code.  Formatters are
" registered with codefmt using maktaba's standard extension registry:
" >
"   let l:codefmt_registry = maktaba#extension#GetRegistry('codefmt')
"   call l:codefmt_registry.AddExtension(l:formatter)
" <
"
" Formatters define these fields:
"   * name (string): The formatter name that will be exposed to users.
"   * setup_instructions (string, optional): A string explaining to users how to
"     make the plugin available if not already available.
" and these functions:
"   * IsAvailable() -> boolean: Whether the formatter is fully functional with
"     all dependencies available. Returns 0 only if setup_instructions have not
"     been followed.
"   * AppliesToBuffer() -> boolean: Whether the current buffer is of a type
"     normally formatted by this formatter. Normally based on 'filetype', but
"     could depend on buffer name or other properties.
" and should implement at least one of the following functions:
"   * Format(): Formats the current buffer directly.
"   * FormatRange({startline}, {endline}): Formats the current buffer, focusing
"     on the range of lines from {startline} to {endline}.
"   * FormatRanges({ranges}): Formats the current buffer, focusing on the given
"     ranges of lines. Each range should be a 2-item list of
"     [startline,endline].
" Formatters should implement the most specific format method that is supported.


""
" @private
" Ensures that {formatter} is a valid formatter, and then prepares it for use by
" codefmt.  See @dict(Formatter) for the API {formatter} must implement.
" @throws BadValue if {formatter} is missing required fields.
" Returns the fully prepared formatter.
function! codefmt#EnsureFormatter(formatter) abort
  let l:required_fields = ['name', 'IsAvailable', 'AppliesToBuffer']
  " Throw BadValue if any required fields are missing.
  let l:missing_fields =
      \ filter(copy(l:required_fields), '!has_key(a:formatter, v:val)')
  if !empty(l:missing_fields)
    throw maktaba#error#BadValue('a:formatter is missing fields: ' .
        \ join(l:missing_fields, ', '))
  endif

  " Throw BadValue if the wrong number of format functions are provided.
  let l:available_format_functions = ['Format', 'FormatRange', 'FormatRanges']
  let l:format_functions = filter(copy(l:available_format_functions),
      \ 'has_key(a:formatter, v:val)')
  if empty(l:format_functions)
    throw maktaba#error#BadValue('Formatter ' . a:formatter.name .
        \ ' has no format functions.  It must have at least one of ' .
        \ join(l:available_format_functions, ', '))
  endif

  " TODO(dbarnett): Check types.

endfunction


""
" @private
" Formatter: js-beautify
function! codefmt#GetJsBeautifyFormatter() abort
  let l:formatter = {
      \ 'name': 'js-beautify',
      \ 'setup_instructions': 'Install js-beautify ' .
          \ '(https://www.npmjs.com/package/js-beautify).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('js_beautify_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'css' || &filetype is# 'html' || &filetype is# 'json' ||
        \ &filetype is# 'javascript'
  endfunction

  ""
  " Reformat the current buffer with js-beautify or the binary named in
  " @flag(js_beautify_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [s:plugin.Flag('js_beautify_executable'), '-f', '-']
    if &filetype != ""
      let l:cmd = l:cmd + ['--type', &filetype]
    endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    let l:lines = getline(1, line('$'))
    " Hack range formatting by formatting range individually, ignoring context.
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")
    " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
    let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
    let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]

    call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
  endfunction

  return l:formatter
endfunction


function! s:ClangFormatHasAtLeastVersion(minimum_version) abort
  if !exists('s:clang_format_version')
    let l:executable = s:plugin.Flag('clang_format_executable')
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
function! codefmt#InvalidateClangFormatVersion() abort
  unlet! s:clang_format_version
endfunction


""
" @private
" Formatter: clang-format
function! codefmt#GetClangFormatFormatter() abort
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
        \ &filetype is# 'proto' || &filetype is# 'javascript'
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


""
" @private
" Formatter: gofmt
function! codefmt#GetGofmtFormatter() abort
  let l:formatter = {
      \ 'name': 'gofmt',
      \ 'setup_instructions': 'Install gofmt or goimports and ' .
          \ 'configure the gofmt_executable flag'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('gofmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'go'
  endfunction


  ""
  " Reformat the current buffer with gofmt or the binary named in
  " @flag(gofmt_executable), only targeting the range between {startline} and
  " {endline}.
  function l:formatter.FormatRange(startline, endline) abort
    " Hack range formatting by formatting range individually, ignoring context.
    let l:cmd = [ s:plugin.Flag('gofmt_executable') ]
    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")
    try
      let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
      let l:formatted = split(l:result.stdout, "\n")
      " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
      let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []

      let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]
      call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
    catch /ERROR(ShellError):/
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for l:line in split(v:exception, "\n")
        let l:tokens = matchlist(l:line,
            \ '\C\v^\<standard input\>:(\d+):(\d+):\s*(.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ 'filename': @%,
              \ 'lnum': l:tokens[1] + a:startline - 1,
              \ 'col': l:tokens[2],
              \ 'text': l:tokens[3]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse gofmt error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction


""
" @private
" Formatter: autopep8
function! codefmt#GetAutopep8Formatter() abort
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


""
" @private
" Formatter: yapf
function! codefmt#GetYAPFFormatter() abort
  let l:formatter = {
      \ 'name': 'yapf',
      \ 'setup_instructions': 'Install yapf ' .
          \ '(https://pypi.python.org/pypi/yapf/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('yapf_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'python'
  endfunction

  ""
  " Reformat the current buffer with yapf or the binary named in
  " @flag(yapf_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:executable = s:plugin.Flag('yapf_executable')

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)
    let l:lines = getline(1, line('$'))

    let l:cmd = [l:executable, '--lines=' . a:startline . '-' . a:endline]
    let l:input = join(l:lines, "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call(0)
    if v:shell_error == 1 " Indicates an error with parsing
      call maktaba#error#Shout('Error formatting file: %s', l:result.stderr)
      return
    endif
    let l:formatted = split(l:result.stdout, "\n")

    call maktaba#buffer#Overwrite(1, line('$'), l:formatted)
  endfunction

  return l:formatter
endfunction


""
" Checks whether {formatter} is available.
" NOTE: If IsAvailable checks are disabled via
" @function(#SetWhetherToPerformIsAvailableChecksForTesting), skips the
" IsAvailable check and always returns true.
function! s:IsAvailable(formatter) abort
  if get(s:, 'check_formatters_available', 1)
    return a:formatter.IsAvailable()
  endif
  return 1
endfunction


""
" Detects whether a formatter has been defined for the current buffer/filetype.
function! codefmt#IsFormatterAvailable() abort
  let l:formatters = copy(s:registry.GetExtensions())
  let l:is_available = 'v:val.AppliesToBuffer() && s:IsAvailable(v:val)'
  return !empty(filter(l:formatters, l:is_available)) ||
      \ !empty(get(b:, 'codefmt_formatter'))
endfunction

function! s:GetSetupInstructions(formatter) abort
  let l:error = 'Formatter "'. a:formatter.name . '" is not available.'
  if has_key(a:formatter, 'setup_instructions')
    let l:error .= ' Setup instructions: ' . a:formatter.setup_instructions
  endif
  return l:error
endfunction

""
" Get formatter based on [name], @setting(b:codefmt_formatter), and defaults.
" If no formatter is available, shout error and return 0.
function! s:GetFormatter(...) abort
  if a:0 >= 1
    let l:explicit_name = a:1
  elseif !empty(get(b:, 'codefmt_formatter'))
    let l:explicit_name = b:codefmt_formatter
  endif
  let l:formatters = s:registry.GetExtensions()
  if exists('l:explicit_name')
    " Explicit name passed.
    let l:selected_formatters = filter(
        \ copy(l:formatters), 'v:val.name == l:explicit_name')
    if empty(l:selected_formatters)
      " No such formatter.
      call maktaba#error#Shout(
          \ '"%s" is not a supported formatter.', l:explicit_name)
      return
    endif
    let l:formatter = l:selected_formatters[0]
    if !s:IsAvailable(l:formatter)
      call maktaba#error#Shout(s:GetSetupInstructions(l:formatter))
      return
    endif
  else
    " No explicit name, use default.
    let l:default_formatters = filter(
        \ copy(l:formatters), 'v:val.AppliesToBuffer() && s:IsAvailable(v:val)')
    if !empty(l:default_formatters)
      let l:formatter = l:default_formatters[0]
    else
      " Check if we have formatters that are not available for some reason.
      " Report a better error message in that case.
      let l:unavailable_formatters = filter(
          \ copy(l:formatters), 'v:val.AppliesToBuffer()')
      if !empty(l:unavailable_formatters)
        let l:error = join(map(copy(l:unavailable_formatters),
            \ 's:GetSetupInstructions(v:val)'), "\n")
      else
        let l:error = 'Not available. codefmt doesn''t have a default ' .
            \ 'formatter for this buffer.'
      endif
      call maktaba#error#Shout(l:error)
      return
    endif
  endif

  return l:formatter
endfunction

""
" Applies [formatter] to the current buffer.
function! codefmt#FormatBuffer(...) abort
  let l:formatter = a:0 >= 1 ? s:GetFormatter(a:1) : s:GetFormatter()
  if l:formatter is# 0
    return
  endif

  try
    if has_key(l:formatter, 'Format')
      call l:formatter.Format()
    elseif has_key(l:formatter, 'FormatRange')
      call l:formatter.FormatRange(1, line('$'))
    elseif has_key(l:formatter, 'FormatRanges')
      call l:formatter.FormatRanges([[1, line('$')]])
    endif
  catch
    call maktaba#error#Shout('Error formatting file: %s', v:exception)
  endtry
endfunction

""
" Applies [formatter] to buffer lines from {startline} to {endline}.
function! codefmt#FormatLines(startline, endline, ...) abort
  call maktaba#ensure#IsNumber(a:startline)
  call maktaba#ensure#IsNumber(a:endline)
  let l:formatter = a:0 >= 1 ? s:GetFormatter(a:1) : s:GetFormatter()
  if l:formatter is# 0
    return
  endif
  try
    if has_key(l:formatter, 'FormatRange')
      call l:formatter.FormatRange(a:startline, a:endline)
    elseif has_key(l:formatter, 'FormatRanges')
      call l:formatter.FormatRanges([[a:startline, a:endline]])
    elseif has_key(l:formatter, 'Format')
      if a:startline is# 1 && a:endline is# line('$')
        " Allow formatting 1,$ as non-range if range formatting isn't supported.
        call l:formatter.Format()
      else
        call maktaba#error#Shout(
            \ 'Range formatting not supported for %s', l:formatter.name)
      endif
    endif
  catch
    call maktaba#error#Shout('Error formatting file: %s', v:exception)
  endtry
endfunction

""
" @public
" Suitable for use as 'operatorfunc'; see |g@| for details.
" The type is ignored since formatting only works on complete lines.
function! codefmt#FormatMap(type) range abort
  call codefmt#FormatLines(line("'["), line("']"))
endfunction

""
" Generate the completion for supported formatters. Lists available formatters
" that apply to the current buffer first, then unavailable formatters that
" apply, then everything else.
function! codefmt#GetSupportedFormatters(ArgLead, CmdLine, CursorPos) abort
  let l:groups = [[], [], []]
  for l:formatter in s:registry.GetExtensions()
    let l:key = l:formatter.AppliesToBuffer() ? (
        \ l:formatter.IsAvailable() ? 0 : 1) : 2
    call add(l:groups[l:key], l:formatter.name)
  endfor
  return join(l:groups[0] + l:groups[1] + l:groups[2], "\n")
endfunction


""
" @private
" Invalidates the cached autopep8 version detection info.
function! codefmt#InvalidateAutopep8Version() abort
  unlet! s:autopep8_supports_range
endfunction


""
" @private
" Configures whether codefmt should bypass FORMATTER.IsAvailable checks and
" assume every formatter is available to avoid checking for executables on the
" path. By default, of course, checks are enabled. If {enable} is 0, they will
" be disabled. If 1, normal behavior with IsAvailable checking is restored.
function! codefmt#SetWhetherToPerformIsAvailableChecksForTesting(enable) abort
  let s:check_formatters_available = a:enable
endfunction
