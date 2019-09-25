using VegaLite
using VegaStreams
using Test

@testset "VegaStreams.jl" begin
    vls = vegastream(@vlplot(:line, x=:x, y=:y))

    for (x, y) in enumerate(randn(100))
        sleep(0.01)
        push!(vls, (x=x, y=y))
    end
end
