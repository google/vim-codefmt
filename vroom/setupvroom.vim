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

" Force
call maktaba#plugin#Get('codefmt').Load()

" Support vroom's fake shell executable and don't try to override it to sh.
call maktaba#syscall#SetUsableShellRegex('\v<shell\.vroomfaker$')
