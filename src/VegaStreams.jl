module VegaStreams

export vegastream

using Electron
using ElectronDisplay
using ElectronDisplay: asset, displayhtml, newdisplay
using JSON

# Based on `ElectronDisplay._display_vegalite`:
function vegalite_html(vlspec)
    if showable("application/vnd.vegalite.v3+json", vlspec)
        major_version_vegalite = "3"
        major_version_vega = "5"
    elseif showable("application/vnd.vegalite.v2+json", vlspec)
        major_version_vegalite = "2"
        major_version_vega = "3"
    else
        error(vlspec, " does not support vegalite v2 or v3.")
    end

    payload = sprint(
        show,
        MIME("application/vnd.vegalite.v$major_version_vegalite+json"),
        vlspec,
    )

    html_page = """
    <html>

    <head>
        <script src="file:///$(asset("vega-$major_version_vega", "vega.min.js"))"></script>
        <script src="file:///$(asset("vega-lite-$major_version_vegalite", "vega-lite.min.js"))"></script>
        <script src="file:///$(asset("vega-embed", "vega-embed.min.js"))"></script>
    </head>
    <body>
        <div id="plotdiv"></div>
    </body>

    <style media="screen">
        .vega-actions a {
            margin-right: 10px;
            font-family: sans-serif;
            font-size: x-small;
            font-style: italic;
        }
    </style>

    <script type="text/javascript">

        var VIEW = null;

        function appendRows(rows) {
            VIEW.insert('table', rows).run();
        };

        var opt = {
            mode: "vega-lite",
            actions: false
        };

        var spec = $payload;
        spec.data = {name: 'table'};

        vegaEmbed('#plotdiv', spec, opt).then(function (result) {
            VIEW = result.view;
        }).catch(console.warn);

    </script>

    </html>
    """
    # See:
    # * https://vega.github.io/vega-lite/tutorials/streaming.html
    # * https://bl.ocks.org/domoritz/8e1e4da185e1a32c7e54934732a8d3d5

    return html_page
end

struct VegaStreamWindow
    window::Electron.Window
    processrow
end

"""
    vegastream(vlspec; processrow=identity, kwargs...)

Open a window containing a Vega-lite plot and a return a handle to it.
This handle supports `push!` and `append!` to update the plot.

# Examples
```jldoctest
julia> using VegaStreams
       using VegaLite

julia> vls = vegastream(@vlplot(:line, x=:x, y=:y));

julia> push!(vls, (x=1, y=2));
```

# Arguments
- `vlspec`: an objection `show`able as `application/vnd.vegalite.v3+json`
  or `application/vnd.vegalite.v2+json`.  The `data` property is ignored.

# Keyword Arguments
- `processrow`: a callable to that process the item(s) given to `push!`
  and `append!` before sending it/them to Vega-Lite.
- Other keyword arguments are passed to `electrondisplay`.  By default,
  `single_window=false` is used.
"""
function vegastream(vlspec; processrow=identity, kwargs...)
    html_page = vegalite_html(vlspec)

    # Using ElectronDisplay internals to support `single_window = false`.
    d = newdisplay(; single_window=false, focus=true, kwargs...)
    options = Dict("webPreferences" => Dict("webSecurity" => false))
    window = displayhtml(d, html_page, options=options)
    #=
    window = electrondisplay(
        "text/html",
        HTML(html_page);
        single_window = false,
        focus = true,
        kwargs...,
    )
    =#

    # TODO: wait for VIEW to be set?
    return VegaStreamWindow(window, processrow)
end

Base.push!(stream::VegaStreamWindow, row) = append!(stream, [row])

function Base.append!(stream::VegaStreamWindow, rows)
    json = JSON.json(collect(map(stream.processrow, rows)))
    run(stream.window, "appendRows($json)")
    return stream
end

"""
    vegastream(vlspec::Dict; ...)

Interpret a dictionary as a Vega-Lite spec.  This is usable without
importing `VegaLite`.
"""
vegastream(vlspec::Dict; kwargs...) = vegastream(SimpleVLSpec(vlspec); kwargs...)

"""
    vegastream(mark::Symbol = :line; processrow=NamedTuple{(:x, :y)}, ...)

A shortcut for creating a simple plotter.
"""
vegastream(mark::Symbol = :line; kwargs...) =
    vegastream(SimpleVLSpec(mark); processrow = NamedTuple{(:x, :y)}, kwargs...)

struct SimpleVLSpec
    params::Dict{String, Any}
end

SimpleVLSpec(mark::Symbol) =
    SimpleVLSpec(Dict(
        "mark" => mark,
        "encoding" => Dict(
            "x" => Dict("field" => "x"),
            "y" => Dict("field" => "y"),
        )
    ))

function Base.show(io::IO, ::MIME"application/vnd.vegalite.v3+json", vlspec::SimpleVLSpec)
    JSON.print(io, vlspec.params)
    return
end

end # module
