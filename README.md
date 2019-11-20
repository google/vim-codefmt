[![Travis Build Status](https://travis-ci.org/google/vim-codefmt.svg?branch=master)](https://travis-ci.org/google/vim-codefmt)

codefmt is a utility for syntax-aware code formatting.  It contains several
built-in formatters, and allows new formatters to be registered by other
plugins.

For details, see the executable documentation in the `vroom/` directory or the
helpfiles in the `doc/` directory. The helpfiles are also available via
`:help codefmt` if codefmt is installed (and helptags have been generated).

# Supported File-types

* [Bazel](https://www.github.com/bazelbuild/bazel) BUILD files (buildifier)
* C, C++ (clang-format)
* CSS, Sass, SCSS, Less (js-beautify)
* Chrome GN files (gn)
* Dart (dartfmt)
* Go (gofmt)
* [GN](https://www.chromium.org/developers/gn-build-configuration) (gn)
* HTML (js-beautify)
* Java (google-java-format or clang-format)
* JavaScript (clang-format or [prettier](https://prettier.io))
* JSON (js-beautify)
* Proto (clang-format)
* Python (Autopep8 or YAPF)
* Rust ([rustfmt](https://github.com/rust-lang/rustfmt))
* TypeScript (clang-format)
* Shell (shfmt)
* [Vue](http://vuejs.org) (prettier)

# Commands

Use `:FormatLines` to format a range of lines or use `:FormatCode` to format
the entire buffer. Use `:NoAutoFormatBuffer` to disable current buffer formatting.

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
Glaive codefmt google_java_executable="java -jar /path/to/google-java-format-VERSION-all-deps.jar"
```

Make sure you have updated maktaba recently. Codefmt depends upon maktaba
to register formatters.

# Autoformatting

Want to just sit back and let autoformat happen automatically? Add this to your
`vimrc` (or any subset):

```vim
augroup autoformat_settings
  autocmd FileType bzl AutoFormatBuffer buildifier
  autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
  autocmd FileType dart AutoFormatBuffer dartfmt
  autocmd FileType go AutoFormatBuffer gofmt
  autocmd FileType gn AutoFormatBuffer gn
  autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
  autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType python AutoFormatBuffer yapf
  " Alternative: autocmd FileType python AutoFormatBuffer autopep8
  autocmd FileType rust AutoFormatBuffer rustfmt
  autocmd FileType vue AutoFormatBuffer prettier
augroup END
```

# Configuring formatters

Most formatters have some options available that can be configured via
[Glaive](https://www.github.com/google/vim-glaive)
You can get a quick view of all codefmt flags by executing `:Glaive codefmt`, or
start typing flag names and use tab completion. See `:help Glaive` for usage
details.

# Installing formatters

Codefmt defines several built-in formatters. The easiest way to see the list of
available formatters is via tab completion: Type `:FormatCode <TAB>` in vim.
Formatters that apply to the current filetype will be listed first.

To use a particular formatter, type `:FormatCode FORMATTER-NAME`. This will
either format the current buffer using the selected formatter or show an error
message with basic setup instructions for this formatter. Normally you will
trigger formatters via key mappings and/or autocommand hooks. See
vroom/main.vroom to learn more about formatting features, and see
vroom/FORMATTER-NAME.vroom to learn more about usage for individual formatters.

## Creating a New Formatter

Assume a filetype `myft` and a formatter called `MyFormatter`. Our detailed
guide to creating a formatter [lives
here](https://github.com/google/vim-codefmt/wiki/Formatter-Integration-Guide).

*   Create an issue for your new formatter and discuss!

*   Create a new file in `autoload/codefmt/myformatter.vim` See
    `autoload/codefmt/buildifier.vim for an example. This is where all the
    logic for formatting goes.

*   Register the formatter in
    [plugin/register.vim](plugin/register.vim)
    with:

    ```vim
    call s:registry.AddExtension(codefmt#myformatter#GetFormatter())
    ```

*   Create a flag in
    [instant/flags.vim](instant/flags.vim)

    ```vim
    ""
    " The path to the buildifier executable.
    call s:plugin.Flag('myformatter_executable', 'myformatter')
    ```

*   Create a [vroom](https://github.com/google/vroom) test named
    `vroom/myformatter.vroom` to ensure your formatter works properly.

*   Update the README.md to mention your new filetype!

That's it! Of course, the complicated step is in the details of
`myformatter.vim`.

// TODO(kashomon): Create a worked example formatter.
