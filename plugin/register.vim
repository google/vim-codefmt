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

let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


let s:registry = s:plugin.GetExtensionRegistry()
call s:registry.SetValidator('codefmt#EnsureFormatter')

" Formatters that are registered later are given more priority when deciding
" what the default formatter will be for a particular file type.
call s:registry.AddExtension(codefmt#prettier#GetFormatter())
call s:registry.AddExtension(codefmt#rustfmt#GetFormatter())
call s:registry.AddExtension(codefmt#jsbeautify#GetFormatter())
call s:registry.AddExtension(codefmt#clangformat#GetFormatter())
call s:registry.AddExtension(codefmt#gofmt#GetFormatter())
call s:registry.AddExtension(codefmt#dartfmt#GetFormatter())
call s:registry.AddExtension(codefmt#yapf#GetFormatter())
call s:registry.AddExtension(codefmt#autopep8#GetFormatter())
call s:registry.AddExtension(codefmt#gn#GetFormatter())
call s:registry.AddExtension(codefmt#buildifier#GetFormatter())
call s:registry.AddExtension(codefmt#googlejava#GetFormatter())
call s:registry.AddExtension(codefmt#shfmt#GetFormatter())
