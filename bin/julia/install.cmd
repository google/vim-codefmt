@echo off
set PROJECT=%~dp0
julia --project="%PROJECT%" -e 'using Pkg; Pkg.instantiate(verbose=true)'
