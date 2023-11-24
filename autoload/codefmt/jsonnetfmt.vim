let s:plugin = maktaba#plugin#Get('codefmt')

if !exists('s:SUPPORTED_FILETYPES')
  let s:SUPPORTED_FILETYPES = ['json', 'jsonnet']
  lockvar! s:SUPPORTED_FILETYPES
endif


""
" @private
"
" Formatter provider for jsonnet files using jsonnetfmt
function! codefmt#jsonnetfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'jsonnetfmt',
      \ 'setup_instructions': 'Install jsonnet. (https://jsonnet.org/).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('jsonnetfmt_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, s:SUPPORTED_FILETYPES)
  endfunction

  ""
  " Reformat the current buffer with jsonnetfmt or the binary named in
  " @flag(jsonnetfmt_executable)
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('jsonnetfmt_executable'), '-' ]

    try
      " NOTE: Ignores any line ranges given and formats entire buffer.
      " jsonnetfmt does not support range formatting.
      call codefmt#formatterhelpers#Format(l:cmd)
    catch
      " TODO: Parse all the errors and stick them in the quickfix list.
      " currently just echoes the errors.
      call maktaba#error#Shout('Error formatting file: %s', v:exception)
    endtry
  endfunction

  return l:formatter
endfunction
