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

" This file can be sourced to install the plugin and its dependencies if no
" plugin manager is available.

let s:codefmt_path = expand('<sfile>:p:h')

if !exists('*maktaba#compatibility#Disable')
  try
    " To check if Maktaba is loaded we must try calling a maktaba function.
    " exists() is false for autoloadable functions that are not yet loaded.
    call maktaba#compatibility#Disable()
  catch /E117:/
    " Maktaba is not installed. Check whether it's in a nearby directory.
    let s:rtpsave = &runtimepath
    " We'd like to use maktaba#path#Join, but maktaba doesn't exist yet.
    let s:slash = exists('+shellslash') && !&shellslash ? '\' : '/'
    let s:guess1 = fnamemodify(s:codefmt_path, ':h') . s:slash . 'maktaba'
    let s:guess2 = fnamemodify(s:codefmt_path, ':h') . s:slash . 'vim-maktaba'
    if isdirectory(s:guess1)
      let &runtimepath .= ',' . s:guess1
    elseif isdirectory(s:guess2)
      let &runtimepath .= ',' . s:guess2
    endif

    try
      " If we've just installed maktaba, we need to make sure that vi
      " compatibility mode is off. Maktaba does not support vi compatibility.
      call maktaba#compatibility#Disable()
    catch /E117:/
      " No luck.
      let &runtimepath = s:rtpsave
      unlet s:rtpsave
      " We'd like to use maktaba#error#Shout, but maktaba doesn't exist yet.
      echohl ErrorMsg
      echomsg 'Maktaba not found, but codefmt requires it. Please either:'
      echomsg '1. Place maktaba in the same directory as this plugin.'
      echomsg '2. Add maktaba to your runtimepath before using this plugin.'
      echomsg 'Maktaba can be found at https://github.com/google/vim-maktaba.'
      echohl NONE
      finish
    endtry
  endtry
endif
call maktaba#plugin#GetOrInstall(s:codefmt_path)
