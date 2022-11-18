" Copyright 2015 Google Inc. All rights reserved.
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
"   * clojure: cljstyle, zprint
"   * dart: dartfmt
"   * fish: fish_indent
"   * gn: gn
"   * go: gofmt
"   * haskell: ormolu
"   * java: google-java-format
"   * javascript, json, html, css: js-beautify
"   * javascript, html, css, markdown: prettier
"   * kotlin: ktfmt
"   * lua: luaformatterfiveone
"   * nix: nixpkgs-fmt
"   * ocaml: ocamlformat
"   * python: autopep8, black, yapf
"   * rust: rustfmt
"   * sh: shfmt
"   * swift: swift-format


let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


let s:registry = s:plugin.GetExtensionRegistry()
call s:registry.SetValidator('codefmt#EnsureFormatter')

" Formatters that are registered later are given more priority when deciding
" what the default formatter will be for a particular file type.
call s:registry.AddExtension(codefmt#buildifier#GetFormatter())
call s:registry.AddExtension(codefmt#clangformat#GetFormatter())
call s:registry.AddExtension(codefmt#cljstyle#GetFormatter())
call s:registry.AddExtension(codefmt#zprint#GetFormatter())
call s:registry.AddExtension(codefmt#dartfmt#GetFormatter())
call s:registry.AddExtension(codefmt#fish_indent#GetFormatter())
call s:registry.AddExtension(codefmt#gn#GetFormatter())
call s:registry.AddExtension(codefmt#gofmt#GetFormatter())
call s:registry.AddExtension(codefmt#googlejava#GetFormatter())
call s:registry.AddExtension(codefmt#jsbeautify#GetFormatter())
call s:registry.AddExtension(codefmt#prettier#GetFormatter())
call s:registry.AddExtension(codefmt#ktfmt#GetFormatter())
call s:registry.AddExtension(codefmt#luaformatterfiveone#GetFormatter())
call s:registry.AddExtension(codefmt#nixpkgs_fmt#GetFormatter())
call s:registry.AddExtension(codefmt#autopep8#GetFormatter())
call s:registry.AddExtension(codefmt#isort#GetFormatter())
call s:registry.AddExtension(codefmt#black#GetFormatter())
call s:registry.AddExtension(codefmt#yapf#GetFormatter())
call s:registry.AddExtension(codefmt#rustfmt#GetFormatter())
call s:registry.AddExtension(codefmt#shfmt#GetFormatter())
call s:registry.AddExtension(codefmt#swiftformat#GetFormatter())
call s:registry.AddExtension(codefmt#ormolu#GetFormatter())
call s:registry.AddExtension(codefmt#ocamlformat#GetFormatter())
