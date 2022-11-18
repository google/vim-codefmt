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
" @order intro formatters config commands autocmds mappings dicts functions
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
" We need at least 1.12.0 so that maktaba#ensure#IsCallable works on Neovim and
" recent Vim (newer than is actually in Travis/Xenial).
" See https://github.com/google/vim-maktaba/issues/173
if !maktaba#IsAtLeastVersion('1.12.0')
  call maktaba#error#Shout('Codefmt requires maktaba version 1.12.0.')
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
" The path to the clang-format executable. String, list, or callable that
" takes no args and returns a string or a list.
call s:plugin.Flag('clang_format_executable', 'clang-format')
" Invalidate cache of detected clang-format version when this is changed,
" regardless of {value} arg.
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
" The path to the black executable.
call s:plugin.Flag('black_executable', 'black')

""
" The path to the isort executable.
call s:plugin.Flag('isort_executable', 'isort')

""
" The path to the gn executable.
call s:plugin.Flag('gn_executable', 'gn')

""
" The path to the buildifier executable.
call s:plugin.Flag('buildifier_executable', 'buildifier')

""
" The lint_mode for buildifier. passed to buildifier --lint parameter.
"
" Options:
" - "" (empty): Use default from buildifier.
" - "Off": Do not fix issues.
" - "Fix": Fix issues automatically during formatting.
" - "Warn": Format only if there are no issues; if there are issues, it will
"   cause an error and do no formatting.
call s:plugin.Flag('buildifier_lint_mode', '')

""
" The warnings options passed to buildifier to modify the defaults. Whatever is
" specified is added to the commandline after "--warnings=". For example, if you
" add this to your config: >
"   Glaive codefmt buildifier_warnings='-module-docstring,+unsorted-dict-items'
" <
" Then buildifier will omit the "module-docstring" warning, but add
" "unsorted-dict-items" (which is ignored by default). This works also in
" fix-mode, in which case dictionary items will be resorted upon buffer save.
"
" Options:
" - "" (empty): Use default warnings from buildifier.
" - "-some-warning": Remove 'some-warning' from the warning set.
" - "+some-warning": Add 'some-warning' to the warning set.
call s:plugin.Flag('buildifier_warnings', '')

""
" The path to the google-java executable.  Generally, this should have the
" form:
" `java -jar /path/to/google-java`
call s:plugin.Flag('google_java_executable', 'google-java-format')

""
" The path to the ktfmt executable with args, as a list. The default value
" assumes there is a wrapper script named `ktfmt`. Without such a script, this
" will generally have the form:
" `ktfmt_executable=java,-jar,/path/to/ktfmt-VERSION-jar-with-dependencies.jar`
"
" Note that range formatting is not fully supported, with a feature request at
" https://github.com/facebookincubator/ktfmt/issues/218. ktfmt will align a
" formatted range to column 1, requiring a manual reindent to match the
" surrounding blocks.
call s:plugin.Flag('ktfmt_executable', ['ktfmt'])

""
" Command line arguments to feed shfmt. Either a list or callable that
" takes no args and returns a list with command line arguments. By default, uses
" the Google's style.
" See https://github.com/mvdan/sh for details.
call s:plugin.Flag('shfmt_options', ['-i', '2', '-sr', '-ci'])

""
" The path to the shfmt executable. String, list, or callable that
" takes no args and returns a string or a list.
call s:plugin.Flag('shfmt_executable', 'shfmt')

""
" Command line arguments to feed prettier. Either a list or callable that
" takes no args and returns a list with command line arguments.
call s:plugin.Flag('prettier_options', [])

""
" The path to the swift-format executable.
call s:plugin.Flag('swift_format_executable', 'swift-format')

""
" @private
function s:LookupPrettierExecutable() abort
  return executable('npx') ? ['npx', '--no-install', 'prettier'] : 'prettier'
endfunction

""
" The path to the prettier executable. String, list, or callable that
" takes no args and returns a string or a list. The default uses npx if
" available, so that the repository-local prettier will have priority.
call s:plugin.Flag('prettier_executable', function('s:LookupPrettierExecutable'))

" Invalidate cache of detected prettier availability whenever
" prettier_executable changes.
call s:plugin.flags.prettier_executable.AddCallback(
    \ maktaba#function#FromExpr('codefmt#prettier#InvalidateIsAvailable()'), 0)

""
" Command line arguments to feed rustfmt. Either a list or callable that
" takes no args and returns a list with command line arguments.
call s:plugin.Flag('rustfmt_options', [])

""
" The path to the rustfmt executable.
call s:plugin.Flag('rustfmt_executable', 'rustfmt')

""
" @private
" This is declared above zprint_options to avoid interfering with vimdoc parsing
" the maktaba flag.
function s:ZprintOptions() abort
  return &textwidth ? ['{:width ' . &textwidth . '}'] : []
endfunction

""
" Command line arguments to feed zprint. Either a list or callable that takes no
" args and returns a list with command line arguments. The default configures
" zprint with Vim's textwidth.
call s:plugin.Flag('zprint_options', function('s:ZprintOptions'))

""
" The path to the zprint executable. Typically this is one of the native
" images (zprintl or zprintm) from https://github.com/kkinnear/zprint/releases
" installed as zprint.
call s:plugin.Flag('zprint_executable', 'zprint')

""
" The path to the fish_indent executable.
call s:plugin.Flag('fish_indent_executable', 'fish_indent')

""
" The path to the nixpkgs-fmt executable.
call s:plugin.Flag('nixpkgs_fmt_executable', 'nixpkgs-fmt')

""
" The path to the luaformatterfiveone executable.
call s:plugin.Flag('luaformatterfiveone_executable', 'luaformatterfiveone')

""
" The path to the cljstyle executable.
call s:plugin.Flag('cljstyle_executable', 'cljstyle')

""
" The path to the ormolu executable.
call s:plugin.Flag('ormolu_executable', 'ormolu')

""
" The path to the ocamlformat executable.
call s:plugin.Flag('ocamlformat_executable', 'ocamlformat')
