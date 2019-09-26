using VegaStreams
using Test

@testset "VegaStreams.jl" begin
    vls = vegastream()
    for row in enumerate(randn(100))
        sleep(0.01)
        push!(vls, row)
    end

    vls = vegastream(:point)
    for (x, y) in enumerate(randn(100))
        sleep(0.01)
        push!(vls, (x=x, y=y))
    end
end
