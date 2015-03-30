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

" This file is used from vroom scripts to bootstrap the codefmt plugin and
" configure it to work properly under vroom.

" Codefmt does not support compatible mode.
set nocompatible

" Install the codefmt plugin.
let s:repo = expand('<sfile>:p:h:h')
execute 'source' s:repo . '/bootstrap.vim'

" Install Glaive from local dir.
let s:search_dir = fnamemodify(s:repo, ':h')
for s:plugin_dirname in ['glaive', 'vim-glaive']
  let s:bootstrap_path =
      \ maktaba#path#Join([s:search_dir, s:plugin_dirname, 'bootstrap.vim'])
  if filereadable(s:bootstrap_path)
    execute 'source' s:bootstrap_path
    break
  endif
endfor

" Force plugin/ files to load since vroom installs the plugin after
" |load-plugins| time.
call maktaba#plugin#Get('codefmt').Load()

" Support vroom's fake shell executable and don't try to override it to sh.
call maktaba#syscall#SetUsableShellRegex('\v<shell\.vroomfaker$')
