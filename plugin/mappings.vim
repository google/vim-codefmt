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
" @section Mappings, mappings
" This plugin provides default mappings that can be enabled via the
" plugin[mappings] flag. You can enable them under the default prefix of
" <Leader>= (<Leader> being "\" by default) or set the plugin[mappings] flag to
" an explicit prefix to use. Or you can define your own custom mappings; see
" plugin/mappings.vim for inspiration.
"
" To format the whole buffer, use <PREFIX>b.
"
" Some formatters also support formatting ranges. There are several mappings for
" formatting ranges that mimic vim's built-in |operator|s:
"   * Format the current line with the <PREFIX>= mapping.
"   * <PREFIX> by itself acts as an |operator|. Use <PREFIX><MOTION> to format
"     over any motion. For instance, <PREFIX>i{ will format all lines inside the
"     enclosing curly braces.
"   * In visual mode, <PREFIX> will format the visual selection.

let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


let s:prefix = s:plugin.MapPrefix('=')


""
" Format the contents of the buffer using the associated formatter.
execute 'nnoremap <unique> <silent>' s:prefix . 'b' ':FormatCode<CR>'

""
" Format over the motion that follows. This is a custom operator.
" For instance, <PREFIX>i{ will format all lines inside the enclosing curly
" braces.
execute 'nnoremap <unique> <silent>' s:prefix
    \ ':set opfunc=codefmt#FormatMap<CR>g@'

""
" Format the current line or range using the formatter associated with the
" current buffer.
execute 'nnoremap <unique> <silent>' s:prefix . '=' ':FormatLines<CR>'

""
" Format the visually selected region using the formatter associated with the
" current buffer.
execute 'vnoremap <unique> <silent>' s:prefix ':FormatLines<CR>'
