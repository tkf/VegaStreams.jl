module VegaStreams

export vegastream

using Base64
using Electron
using ElectronDisplay
using ElectronDisplay: asset, displayhtml, newdisplay
using JSON

# Based on `ElectronDisplay._display_vegalite`:
function vegalite_html(vlspec)
    if showable("application/vnd.vegalite.v2+json", vlspec)
        major_version_vegalite = "2"
        major_version_vega = "3"
    elseif showable("application/vnd.vegalite.v3+json", vlspec)
        major_version_vegalite = "3"
        major_version_vega = "5"
    else
        error(vlspec, " does not support vegalite v2 or v3.")
    end

    payload = stringmime(
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
end

function vegastream(vlspec; kwargs...)
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
        kwargs...,
    )
    =#

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
