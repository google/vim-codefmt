codefmt is a utility for syntax-aware code formatting.  codefmt relies on
[codefmtlib](https://github.com/google/vim-codefmtlib) for registeration and
management of formatting plugins.

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
Plugin 'google/vim-codefmtlib'
Plugin 'google/vim-codefmt'
```

