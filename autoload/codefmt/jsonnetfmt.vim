let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
"
" Formatter provider for jsonnet files using jsonnetfmt
function! codefmt#jsonnetfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'jsonnetfmt',
      \ 'setup_instructions': 'Install jsonnet. ' .
          \ '(https://jsonnet.org/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('jsonnetfmt_executable'))
  endfunction

  let l:supported_filetypes = ['json','jsonnet']

  function l:formatter.AppliesToBuffer() abort
    return index(l:supported_filetypes, &filetype) >= 0
  endfunction

  ""
  " Reformat the current buffer with jsonnetfmt or the binary named in
  " @flag(jsonnetfmt_executable)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('jsonnetfmt_executable') ]
    let l:fname = expand('%:p')
    if !empty(l:fname)
      let l:cmd += ['-path', l:fname]
    endif

    try
      " NOTE: Ignores any line ranges given and formats entire buffer.
      " jsonnetfmt does not support range formatting.
      call codefmt#formatterhelpers#Format(l:cmd)
    catch
      " Parse all the errors and stick them in the quickfix list.
      call maktaba#error#Shout('Error formatting file: %s', v:exception)
    endtry
  endfunction

  return l:formatter
endfunction
