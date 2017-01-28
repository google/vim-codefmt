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
"   * bzl (Bazel): buildifier
"   * c, cpp, proto, javascript, typescript: clang-format
"   * go: gofmt
"   * python: autopep8, yapf
"   * gn: gn
"   * dart: dartfmt


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
" Checks whether {formatter} is available.
" NOTE: If IsAvailable checks are disabled via
" @function(#SetWhetherToPerformIsAvailableChecksForTesting), skips the
" IsAvailable check and always returns true.
function! s:IsAvailable(formatter) abort
  if codefmt#ShouldPerformIsAvailableChecks()
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
" Returns whether to perform Availability checks, which is normall set for
" testing. Defaults to 1 (enable availablity checks).
function! codefmt#ShouldPerformIsAvailableChecks() abort
  return get(s:, 'check_formatters_available', 1)
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
