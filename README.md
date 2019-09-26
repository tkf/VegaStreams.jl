# VegaStreams

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/VegaStreams.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/VegaStreams.jl/dev)
[![Build Status](https://travis-ci.com/tkf/VegaStreams.jl.svg?branch=master)](https://travis-ci.com/tkf/VegaStreams.jl)
[![Codecov](https://codecov.io/gh/tkf/VegaStreams.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/VegaStreams.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/VegaStreams.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/VegaStreams.jl?branch=master)

### Example

```julia
julia> using VegaStreams
       using VegaLite

julia> vls = vegastream(@vlplot(:line, x=:x, y=:y));

julia> for (x, y) in enumerate(randn(100))
           sleep(0.01)
           push!(vls, (x=x, y=y))
       end
```
