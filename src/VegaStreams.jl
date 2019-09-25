module VegaStreams

export vegastream

using Base64
using Electron
using ElectronDisplay
using ElectronDisplay: asset
using JSON

struct VegaStreamPlotter
    vlspec

    function VegaStreamPlotter(vlspec)
        @assert showable("application/vnd.vegalite.v2+json", vlspec) ||
            showable("application/vnd.vegalite.v3+json", vlspec)
        return new(vlspec)
    end
end

# Based on `ElectronDisplay._display_vegalite`:
function Base.show(io::IO, ::MIME"text/html", plotter::VegaStreamPlotter)
    if showable("application/vnd.vegalite.v2+json", plotter.vlspec)
        major_version_vegalite = "2"
        major_version_vega = "3"
    elseif showable("application/vnd.vegalite.v3+json", plotter.vlspec)
        major_version_vegalite = "3"
        major_version_vega = "5"
    else
        error(plotter.vlspec, " does not support vegalite v2 or v3.")
    end

    payload = stringmime(
        MIME("application/vnd.vegalite.v$major_version_vegalite+json"),
        plotter.vlspec,
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

    print(io, html_page)
end

struct VegaStreamWindow
    window::Electron.Window
end

function vegastream(vlspec; kwargs...)
    window = electrondisplay(
        "text/html",
        VegaStreamPlotter(vlspec);
        single_window = true,
        kwargs...,
    )
    # TODO: wait for VIEW to be set?
    return VegaStreamWindow(window)
end

Base.push!(stream::VegaStreamWindow, row) = append!(stream, [row])

function Base.append!(stream::VegaStreamWindow, rows)
    json = JSON.json(collect(rows))
    run(stream.window, "appendRows($json)")
    return stream
end

end # module
