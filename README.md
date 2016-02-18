[![Travis Build Status](https://travis-ci.org/google/vim-codefmt.svg?branch=master)](https://travis-ci.org/google/vim-codefmt)

codefmt is a utility for syntax-aware code formatting.  It contains several
built-in formatters, and allows new formatters to be registered by other
plugins.

For details, see the executable documentation in the `vroom/` directory or the
helpfiles in the `doc/` directory. The helpfiles are also available via
`:help codefmt` if codefmt is installed (and helptags have been generated).

# Commands

Use `:FormatLines` to format a range of lines or use `:FormatCode` to format
the entire buffer.

# Usage example

Before:

```cpp
int foo(int * x) { return * x** x ; }
```

After running `:FormatCode`:

```cpp
int foo(int* x) { return *x * *x; }
```

# Installation

This example uses [Vundle](https://github.com/gmarik/Vundle.vim), whose
plugin-adding command is `Plugin`.

```vim
" Add maktaba and codefmt to the runtimepath.
" (The latter must be installed before it can be used.)
Plugin 'google/vim-maktaba'
Plugin 'google/vim-codefmt'
" Also add Glaive, which is used to configure codefmt's maktaba flags. See
" `:help :Glaive` for usage.
Plugin 'google/vim-glaive'
" ...
call vundle#end()
" the glaive#Install() should go after the "call vundle#end()"
call glaive#Install()
" Optional: Enable codefmt's default mappings on the <Leader>= prefix.
Glaive codefmt plugin[mappings]
```

Make sure you have updated maktaba recently. Codefmt depends upon maktaba
to register formatters.

# Installing and configuring formatters

Codefmt defines several built-in formatters. The easiest way to see the list of
available formatters is via tab completion: Type `:FormatCode <TAB>` in vim.
Formatters that apply to the current filetype will be listed first.

To use a particular formatter, type `:FormatCode FORMATTER-NAME`. This will
either format the current buffer using the selected formatter or show an error
message with basic setup instructions for this formatter. Normally you will
trigger formatters via key mappings and/or autocommand hooks. See
vroom/main.vroom to learn more about formatting features, and see
vroom/FORMATTER-NAME.vroom to learn more about usage for individual formatters.

Most formatters have some options available that can be configured via Glaive.
You can get a quick view of all codefmt flags by executing `:Glaive codefmt`, or
start typing flag names and use tab completion. See `:help Glaive` for usage
details.
