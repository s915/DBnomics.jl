"""
    rdb_by_api_link(
        api_link::String;
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        filters::Union{Nothing, Dict, Tuple} = DBnomics.filters,
        kwargs...
    )

`rdb_by_api_link` downloads data series from [DBnomics](https://db.nomics.world/).

This function gives you access to hundreds of millions data series from DBnomics.
The code of each series is given on the [DBnomics](https://db.nomics.world/) website.

# Arguments
- `api_link::String`: DBnomics API link of the search.
- `use_readlines::Bool = DBnomics.use_readlines`: (default `false`) If `true`, then
  the data are requested and read with the function `readlines`.
- `curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config`: (default `nothing`)
  If not `nothing`, it is used to configure a proxy connection. This
  configuration is passed to the keyword arguments of the function `HTTP.get` or `HTTP.post` of
  the package **HTTP.jl**.
- `filters::Union{Nothing, Dict, Tuple} = DBnomics.filters`: (default `nothing`)
  This argument must be a `Dict` for one filter because the function `json` of the
  package **JSON.jl** is used before sending the request to the server. For multiple
  filters, you have to provide a `Tuple` of valid filters (see examples).
  A valid filter is a `Dict` with a key `code` which value is a character string,
  and a key `parameters` which value is a `Dict` with keys `frequency`
  and `method` or `nothing`.
- `kwargs...`: Keyword arguments to be passed to `HTTP.get` or `HTTP.post`.

# Examples
```jldoctest
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");

julia> df2 = rdb_by_api_link("https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22indicator%22%3A%5B%22IC.REG.PROC.FE.NO%22%5D%7D&q=Doing%20Business&observations=1&format=json&align_periods=1&offset=0&facets=0");


## Use proxy with curl
julia> h = Dict(:proxy => "http://<proxy>:<port>");

julia> DBnomics.options("curl_config", h);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");
# or
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX", curl_config = h);

# Regarding the functioning of HTTP.jl, you might need to modify another option
# It will change the url from https:// to http://
# (https://github.com/JuliaWeb/HTTP.jl/pull/390)
julia> DBnomics.options("secure", false);


## Use readlines and download
julia> DBnomics.options("use_readlines", true);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");
# or
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX", use_readlines = true);


## Apply filter(s) to the series
# One filter
julia> filters = Dict(:code => "interpolate", :parameters => Dict(:frequency => "daily", :method => "spline"));
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series/IMF/WEO/ABW.BCA?observations=1", filters = filters);

# Two filters
julia> filter1 = Dict(:code => "interpolate", :parameters => Dict(:frequency => "quarterly", :method => "spline"));
julia> filter2 = Dict(:code => "aggregate", :parameters => Dict(:frequency => "annual", :method => "average"));
julia> filters = (filter1, filter2);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series/IMF/WEO/ABW.BCA?observations=1", filters = filters);

julia> filter1 = Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "linear"));
julia> filter2 = Dict(:code => "x13", :parameters => nothing);
julia> filters = (filter1, filter2);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=ECB/EXR/A.AUD.EUR.SP00.A", filters = filters);
```
"""
function rdb_by_api_link(
    api_link::String;
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    filters::Union{Nothing, Dict, Tuple} = DBnomics.filters,
    kwargs...
)
    dot_rdb(
        api_link;
        use_readlines = use_readlines,
        curl_config = curl_config,
        filters = filters,
        kwargs...
    )
end
