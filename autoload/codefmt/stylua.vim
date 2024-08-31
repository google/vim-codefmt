let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
"
" Formatter provider for lua files using stylua.
function! codefmt#stylua#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'stylua',
      \ 'setup_instructions': 'Install stylua (https://github.com/JohnnyMorganz/StyLua).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('stylua_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'lua')
  endfunction

  ""
  " Reformat the current buffer with stylua or the binary named in
  " @flag(stylua_executable)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [s:plugin.Flag('stylua_executable')]
    " Specify we are sending input through stdin
    let l:cmd += ['--stdin-filepath', expand('%:p'), '-']

    try
      call codefmt#formatterhelpers#Format(l:cmd)
    catch
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for line in split(v:exception, "\n")
        let l:fname_pattern = 'stdin'
        let l:tokens = matchlist(line, '\C\v^\[string "isCodeValid"\]:(\d+): (.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ "filename": @%,
              \ "lnum": l:tokens[1],
              \ "text": l:tokens[2]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse stylua error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
