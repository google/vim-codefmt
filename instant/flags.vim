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
" @section Introduction, intro
" @order intro config formatters dicts commands autocmds functions mappings
" Provides a @command(FormatCode) command to intelligently reformat code.

""
" @setting b:codefmt_formatter
" You can override the default formatter by defining this variable. For
" instance, to explicitly select the clang-format formatter for Java, add >
"   autocmd FileType java let b:codefmt_formatter = 'clang-format'
" < to your vimrc. You can also set the value to an empty string to disable all
" formatting.


let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


" Shout if maktaba is too old. Done here to ensure it's always triggered.
if !maktaba#IsAtLeastVersion('1.10.0')
  call maktaba#error#Shout('Codefmt requires maktaba version 1.10.0.')
  call maktaba#error#Shout('You have maktaba version %s.', maktaba#VERSION)
  call maktaba#error#Shout('Please update your maktaba install.')
endif


""
" The path to the autopep8 executable.
call s:plugin.Flag('autopep8_executable', 'autopep8')
" Invalidate cache of detected autopep8 version when this is changed, regardless
" of {value} arg.
call s:plugin.flags.autopep8_executable.AddCallback(
    \ maktaba#function#FromExpr('codefmt#autopep8#InvalidateVersion()'), 0)

""
" The path to the clang-format executable.
call s:plugin.Flag('clang_format_executable', 'clang-format')
" Invalidate cache of detected clang-format version when this is changed, regardless
" of {value} arg.
call s:plugin.flags.clang_format_executable.AddCallback(
    \ maktaba#function#FromExpr('codefmt#clangformat#InvalidateVersion()'), 0)

""
" Formatting style for clang-format to use. Either a string or callable that
" takes no args and returns a style name for the current buffer.
" See http://clang.llvm.org/docs/ClangFormatStyleOptions.html for details.
call s:plugin.Flag('clang_format_style', 'file')

""
" The path to the gofmt executable. For example, this can be changed to
" "goimports" (https://godoc.org/golang.org/x/tools/cmd/goimports) to
" additionally adjust imports when formatting.
call s:plugin.Flag('gofmt_executable', 'gofmt')

""
" The path to the dartfmt executable.
call s:plugin.Flag('dartfmt_executable', 'dartfmt')

""
" The path to the js-beautify executable.
call s:plugin.Flag('js_beautify_executable', 'js-beautify')

""
" The path to the yapf executable.
call s:plugin.Flag('yapf_executable', 'yapf')

""
" The path to the gn executable.
call s:plugin.Flag('gn_executable', 'gn')

""
" The path to the buildifier executable.
call s:plugin.Flag('buildifier_executable', 'buildifier')

""
" The path to the google-java executable.  Generally, this should have the
" form:
" `java -jar /path/to/google-java`
call s:plugin.Flag('google_java_executable', 'google-java-format')

""
" Command line arguments to feed shfmt. Either a list or callable that
" takes no args and returns a list with command line arguments. By default, uses
" the Google's style.
" See https://github.com/mvdan/sh for details.
call s:plugin.Flag('shfmt_options', ['-i', '2', '-sr', '-ci'])

""
" The path to the shfmt executable.
call s:plugin.Flag('shfmt_executable', 'shfmt')

""
" Command line arguments to feed prettier. Either a list or callable that
" takes no args and returns a list with command line arguments.
call s:plugin.Flag('prettier_options', [
    \ '--single-quote', '--trailing-comma=all',
    \ '--arrow-parens=always', '--print-width=80'])

""
" The path to the prettier executable.
call s:plugin.Flag('prettier_executable', 'prettier')

""
" Command line arguments to feed rustfmt. Either a list or callable that
" takes no args and returns a list with command line arguments.
call s:plugin.Flag('rustfmt_options', [])

""
" The path to the rustfmt executable.
call s:plugin.Flag('rustfmt_executable', 'rustfmt')
