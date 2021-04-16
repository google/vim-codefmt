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
" Formatter: js-beautify
function! codefmt#jsbeautify#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'js-beautify',
      \ 'setup_instructions': 'Install js-beautify ' .
          \ '(https://www.npmjs.com/package/js-beautify).'}

  " Mapping of jsbeautify type to vim filetype name.
  " TODO: Support jsx and other variants?
  let l:formatter._supported_formats = {
      \ 'js': ['javascript', 'json'],
      \ 'css': ['css', 'sass', 'scss', 'less'],
      \ 'html': ['html']}

  function l:formatter.IsAvailable() dict abort
    return executable(s:plugin.Flag('js_beautify_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() dict abort
    return self._GetSupportedFormatName(&filetype) isnot 0
  endfunction

  ""
  " Reformat the current buffer with js-beautify or the binary named in
  " @flag(js_beautify_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) dict abort
    let l:cmd = [s:plugin.Flag('js_beautify_executable'), '-f', '-']
    " Add --type if known
    if !empty(&filetype)
      let l:format_name = self._GetSupportedFormatName(&filetype)
      if l:format_name is 0
        let l:format_name = &filetype
      endif
      let l:cmd += ['--type', l:format_name]
    endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    " js-beautify does not support range formatting yet:
    " https://github.com/beautify-web/js-beautify/issues/610
    call codefmt#formatterhelpers#AttemptFakeRangeFormatting(
        \ a:startline, a:endline, l:cmd)
  endfunction

  function l:formatter._GetSupportedFormatName(filetype) dict abort
    " Simplify compound filetypes like "html.mustache" down to just "html".
    " TODO: Support other compound filetypes like "javascript.*" and "css.*"?
    let l:filetype = substitute(a:filetype, '\m^html\..*', 'html', '')
    for [l:format_name, l:filetypes] in items(self._supported_formats)
      if index(l:filetypes, l:filetype) >= 0
        return l:format_name
      endif
    endfor
    return 0
  endfunction

  return l:formatter
endfunction

