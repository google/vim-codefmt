#!/usr/bin/env julia
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This program wraps the JuliaFormatter package with a command line interface
# that takes ranges of lines. Example:
#   format.jl --file-path path/to/mycode.jl --lines 1:7 20:35 < mycode.jl
# The bin/format.jl script that ships with JuliaFormatter doesn't take input
# on stdin and doesn't support line ranges, both of which are nice features for
# the vim-codefmt plugin.  The --file-path flag lets this program find
# .JuliaFormatter.toml files to determine code style preferences.

try
  @eval using JuliaFormatter
catch ArgumentError
  println(
    stderr,
    "Missing JuliaFormatter package, run $(dirname(PROGRAM_FILE))/install"
  )
  exit(2)
end
try
  @eval using ArgParse
catch ArgumentError
  println(
    stderr,
    "Missing ArgParse package, run $(dirname(PROGRAM_FILE))/install"
  )
  exit(2)
end

"A range of line numbers to format.  Requires `0 < first <= last`."
struct LineRange
  first::Int
  last::Int
  LineRange(first, last) =
    first <= 0 || last < first ? error("Invalid line range $first:$last") :
    new(first, last)
end

Base.string(r::LineRange) = "$(r.first):$(r.last)"

function ArgParse.parse_item(::Type{LineRange}, s::AbstractString)
  parts = split(s, ':')
  length(parts) == 2 ||
    throw(ArgumentError("LineRange expecting start:end, got $s"))
  LineRange(parse(Int, parts[1]), parse(Int, parts[2]))
end

"Entry point to run format.jl.  argv is the command line arguments."
function main(argv::Vector{<:AbstractString})
  s = ArgParseSettings(
    "$(basename(PROGRAM_FILE)): format all or part of Julia code read from stdin",
    autofix_names=true
  )
  @add_arg_table! s begin
  #! format: off
    "--file_path"
      help = "file path of the code (default: current working directory)"
      metavar = "path/to/file.jl"
    "--lines"
      help = "line range(s) to format (1-based)"
      arg_type = LineRange
      metavar = "first:last"
      nargs = '*'
    "--check_install"
      help = "exit with status 0 if dependencies are installed, 2 otherwise"
      action = :store_true
  #! format: on
  end
  args = parse_args(argv, s, as_symbols=true)
  if args[:check_install]
    exit(0) # if we got this far, module import succeeded
  end
  file_path = let p = args[:file_path]
    fakefile = "file-path-not-specified"
    isnothing(p) ? joinpath(pwd(), fakefile) : abspath(expanduser(p))
  end
  # Sort line ranges and check for overlap, which would make things complicated
  ranges = sort(args[:lines], by=x -> x.first)
  for i = 2:length(ranges)
    if ranges[i].first <= ranges[i-1].last
      println(
        stderr,
        "Overlapping --lines ranges $(ranges[i-1]) and $(ranges[i])"
      )
      exit(3)
    end
  end

  config = JuliaFormatter.Configuration(
    Dict{String,Any}(JuliaFormatter.find_config_file(file_path))
  )
  opts = [Symbol(k) => v for (k, v) in pairs(config)]
  try
    if isempty(ranges)
      input = read(stdin, String)
      output = JuliaFormatter.format_text(input; opts...)
      print(output)
    else
      formatranges(ranges, opts)
    end
  catch e
    message = isdefined(e, :msg) ? e.msg : string(e)
    println(stderr, "Format error: $message")
    exit(1)
  end
end

"""Formats one or more line ranges of `stdin` using options `opts`.
Assumes `ranges` is already sorted.  Prints formatted result to `stdout`.
"""
function formatranges(ranges::Vector{LineRange}, opts)
  # JuliaFormatter doesn't support line ranges, so use format comment directives
  # to turn it on and off at appropriate times.  Use a random number as a marker
  # so added directives can be removed after.
  # NOTE: This approach means line numbers for syntax errors are misleading.
  marker = string(rand(UInt32))
  formaton = "# added:$marker\n#! format: on\n"
  formatoff = "# added:$marker\n#! format: off\n"
  formatpat = r"\s*#! format: (on|off)\s*$"
  lines = readlines(stdin)
  lnum = 1 # current index in lines; unaffected by directive additions
  text = IOBuffer() # will contain the input file with format directives added
  requested = true # whether formatting would be on at this point if the formatting were done without line ranges
  # disable formatting unless line 1 is in range
  if ranges[1].first > 1
    print(text, formatoff)
  end
  for (ri, range) in enumerate(ranges)
    # for each line range, add all the lines leading up to the range to text,
    # disabling any format directives so we don't turn formatting on outside of
    # the requested ranges
    for i = lnum:range.first-1
      if lnum > length(lines)
        @goto eof
      end
      line = lines[lnum]
      lnum += 1
      # disable existing formatter directives
      if (m = match(formatpat, line)) !== nothing
        line = "# disabled:$marker:$line"
        requested = m.captures[1] == "on"
      end
      println(text, line)
    end
    # if directives wouldn't have disabled this range, turn on formatting
    if requested
      print(text, formaton)
    end
    # add each line in the range to text
    for i = range.first:range.last
      if lnum > length(lines)
        @goto eof
      end
      line = lines[lnum]
      lnum += 1
      # if there's a format:off directive inside the range, respect that;
      # if there's a format:on directive inside the range and formatting had
      # been off, enable it at this point
      if (m = match(formatpat, line)) !== nothing
        line = "# disabled:$marker:$line"
        if m.captures[1] == "on" && !requested
          requested = true
          print(text, formaton)
        elseif m.captures[1] == "off" && requested
          requested = false
          print(text, formatoff)
        end
      end
      println(text, line)
    end
    # turn off formatting at the end of the range
    if lnum <= length(lines)
      print(text, formatoff)
    end
  end
  # process lines after the last range
  while lnum <= length(lines)
    line = lines[lnum]
    lnum += 1
    if occursin(formatpat, line)
      line = "# disabled:$marker:$line"
    end
    println(text, line)
  end
  @label eof
  # work around https://github.com/domluna/JuliaFormatter.jl/issues/777
  # by appending on and off directives at the end
  print(text, formaton)
  print(text, formatoff)
  # now that format directives have been added, format the whole thing
  input = String(take!(text))
  output = JuliaFormatter.format_text(input; opts...)
  # remove format directives we added and restore ones we disabled
  skipnext = false
  addedpat = Regex("^\\s*#\\s*added:$marker\\s*\$")
  disabledpat = Regex("^\\s*#\\s*disabled:$marker:(.*)", "s")
  all = []
  last = "nothing"
  for (i, line) in enumerate(readlines(IOBuffer(output)))
    push!(all, line)
    last = line
    if skipnext
      skipnext = false
    elseif occursin(addedpat, line)
      skipnext = true
    else
      if (m = match(disabledpat, line)) !== nothing
        line = m.captures[1]
      end
      println(line)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  main(ARGS)
end
