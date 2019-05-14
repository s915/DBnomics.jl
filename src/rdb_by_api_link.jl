"""
    rdb_by_api_link(
        api_link::String;
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
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
  configuration is passed to the keyword arguments of the function `HTTP.get` of
  the package *HTTP*.
- `kwargs...`: Keyword arguments to be passed to `HTTP.get`.

# Examples
```jldoctest
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");

julia> df2 = rdb_by_api_link("https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22indicator%22%3A%5B%22IC.REG.PROC.FE.NO%22%5D%7D&q=Doing%20Business&observations=1&format=json&align_periods=1&offset=0&facets=0");


## Use proxy with curl
julia> h = Dict(:proxy => "<proxy>", :proxyport => <port>, :proxyusername => "<username>", :proxypassword => "<password>");

julia> DBnomics.options("curl_config", h);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");
# or
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX", curl_config = h)


## Use readlines and download
julia> DBnomics.options("use_readlines", true);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");
# or
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX", use_readlines = true);
```
"""
function rdb_by_api_link(
    api_link::String;
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    kwargs...
)
    if isa(curl_config, Nothing)
        curl_config = kwargs
    end

    DBdata = get_data(api_link, use_readlines, 0; curl_config...)

    api_version = DBdata["_meta"]["version"]
    
    num_found = DBdata["series"]["num_found"]
    limit = DBdata["series"]["limit"]

    DBdata = DBdata["series"]["docs"]
    DBdata = to_dataframe.(DBdata)
    DBdata = reduce(concatenate_data, DBdata)
    change_type!(DBdata)
    transform_date_timestamp!(DBdata)

    if num_found > limit
        iter = 1:Int(floor(num_found / limit))

        if occursin(r"offset=", api_link)
            api_link = replace(api_link, r"\&offset=[0-9]+" => "")
            api_link = replace(api_link, r"\?offset=[0-9]+" => "")
        end
        sep = occursin(r"\?", api_link) ? "&" : "?"

        DBdata2 = map(iter) do u
            link = api_link * sep * "offset=" * string(Int(u * limit))
            tmp_up = get_data(link, use_readlines, 0; curl_config...)
            tmp_up = tmp_up["series"]["docs"]
            tmp_up = to_dataframe.(tmp_up)
            tmp_up = reduce(concatenate_data, tmp_up)
            change_type!(tmp_up)
            transform_date_timestamp!(tmp_up)
            tmp_up
        end

        DBdata = vcat(DBdata, DBdata2)

        DBdata2 = nothing
    end

    if isa(DBdata, Array{DataFrame, 1})
        DBdata = reduce(concatenate_data, DBdata)
    end

    try
        rename!(DBdata, :period => :original_period)
    catch
        error(
            "The retrieved dataset doesn't have a column named 'period', " *
            "it's not normal please check <db.nomics.world>."
        )
    end

    try
        rename!(DBdata, :period_start_day => :period)
    catch
      error(
          "The retrieved dataset doesn't have a column named " *
          "'period_start_day', it's not normal please check <db.nomics.world>."
      )
    end

    DBdata
end
