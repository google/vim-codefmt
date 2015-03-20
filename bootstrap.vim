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

let s:codefmt_path = expand('<sfile>:p:h')

function! s:FindAndAppendToRuntimePath(dir) abort
    " We'd like to use maktaba#path#Join, but maktaba doesn't exist yet.
    let s:slash = exists('+shellslash') && !&shellslash ? '\' : '/'
    let s:guess1 = fnamemodify(s:codefmt_path, ':h') . s:slash . a:dir
    let s:guess2 = fnamemodify(s:codefmt_path, ':h') . s:slash . 'vim-' . a:dir
    if isdirectory(s:guess1)
      let &runtimepath .= ',' . s:guess1
    elseif isdirectory(s:guess2)
      let &runtimepath .= ',' . s:guess2
    endif
endfunction

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
if !maktaba#IsAtLeastVersion('1.9.0')
  call maktaba#error#Shout('Codefmt requires maktaba version 1.9.0.')
  call maktaba#error#Shout('You have maktaba version %s.', maktaba#VERSION)
  call maktaba#error#Shout('Please update your maktaba install.')
endif

function! s:InstallFromLocalDirs(plugin) abort
  let l:parent_dir = fnamemodify(s:codefmt_path, ':h')
  let l:guess1 = maktaba#path#Join([l:parent_dir, a:plugin])
  let l:guess2 = maktaba#path#Join([l:parent_dir, 'vim-' . a:plugin])
  if maktaba#path#Exists(s:guess1)
    call maktaba#plugin#GetOrInstall(l:guess1).Load()
  elseif maktaba#path#Exists(s:guess2)
    call maktaba#plugin#GetOrInstall(l:guess2).Load()
  endif
endfunction

call s:InstallFromLocalDirs('glaive')

let s:codefmt_plugin = maktaba#plugin#GetOrInstall(s:codefmt_path)
call s:codefmt_plugin.Load()
