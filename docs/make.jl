using Documenter, VegaStreams

makedocs(;
    modules=[VegaStreams],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/VegaStreams.jl/blob/{commit}{path}#L{line}",
    sitename="VegaStreams.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/VegaStreams.jl",
)
