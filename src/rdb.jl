"""
    rdb(
        provider_code::Union{Array, String, Nothing} = nothing,
        dataset_code::Union{String, Nothing} = nothing,
        mask_arg::Union{String, Nothing} = nothing;
        ids::Union{Array, String, Nothing} = nothing,
        dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing,
        mask::Union{String, Nothing} = nothing,
        query::Union{String, Nothing} = nothing,
        api_link::Union{String, Nothing} = nothing,
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        filters::Union{Nothing, Dict, Tuple} = DBnomics.filters,
        kwargs...
    )

`rdb` downloads data series from [DBnomics](https://db.nomics.world/) using shortcuts
like `ids`, `dimensions`, `mask`, `query` or using an `api_link`.

This function gives you access to hundreds of millions data series from
[DBnomics](https://db.nomics.world/). The code of each series is given on the
[DBnomics](https://db.nomics.world/) website.

In the event that the shortcut `ids` is used then the argument name can be
dropped and the `ids` will be passed through `provider_code`.

If only the argument `api_link` is provided, then the argument name can be dropped.
The string is directly passed to `api_link`.

In the same way, if only `provider_code`, `dataset_code` and `mask` are used then
the arguments names can be dropped. The `mask` will be passed through `mask_arg`.

By default, the function returns a `DataFrame`.

# Arguments
- `provider_code::Union{Array, String, Nothing} = nothing`: DBnomics code of the
  provider.
- `dataset_code::Union{String, Nothing} = nothing`: DBnomics code of the dataset.
- `mask_arg::Union{String, Nothing} = nothing`: DBnomics code of one or several masks in
  the specified provider and dataset. It is used if the arguments names are not given.
- `ids::Union{Array, String, Nothing} = nothing`: DBnomics code of one or several series.
- `dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing`: DBnomics code of one
  or several dimensions in the specified provider and dataset. If it is a `Dict` or a
  `NamedTuple`, then then function `json` (from the package **JSON.jl**) is applied to
  generate the json object.
- `mask::Union{String, Nothing} = nothing`: DBnomics code of one or several masks in
  the specified provider and dataset.
- `query::Union{String, Nothing} = nothing`: A query to filter/select series from a
  provider's dataset.
- `api_link::Union{String, Nothing} = nothing`: DBnomics API link of the search.
  It should starts with `http://` or `https://`.
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
## By ids
julia> df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
# or
julia> df1 = rdb("AMECO/ZUTN/EA19.1.0.0.0.ZUTN");

julia> df2 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"]);

julia> df3 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "IMF/BOP/A.FR.BCA_BP6_EUR"]);


## By dimensions
julia> df1 = rdb("AMECO", "ZUTN", dimensions = Dict(:geo => "ea12"));
# or
julia> df1 = rdb("AMECO", "ZUTN", dimensions = (geo = "ea12",));

julia> df2 = rdb("AMECO", "ZUTN", dimensions = Dict(:geo => ["ea12", "dnk"]));
# or
julia> df2 = rdb("AMECO", "ZUTN", dimensions = (geo = ["ea12", "dnk"],));

julia> dim = Dict(:country => ["DZ", "PE"], :indicator => ["ENF.CONT.COEN.COST.ZS", "IC.REG.COST.PC.FE.ZS"]);
julia> df3 = rdb("WB", "DB", dimensions = dim);
# or
julia> dim = (country = ["DZ", "PE"], indicator = ["ENF.CONT.COEN.COST.ZS", "IC.REG.COST.PC.FE.ZS"]);
julia> df3 = rdb("WB", "DB", dimensions = dim);


## By mask
julia> df1 = rdb("IMF", "BOP", mask = "A.FR.BCA_BP6_EUR");
# or
julia> df1 = rdb("IMF", "BOP", "A.FR.BCA_BP6_EUR");

julia> df2 = rdb("IMF", "BOP", mask = "A.FR+ES.BCA_BP6_EUR");

julia> df3 = rdb("IMF", "BOP", mask = "A..BCA_BP6_EUR");

julia> df4 = rdb("IMF", "BOP", mask = "A.FR.BCA_BP6_EUR+IA_BP6_EUR");


## By query
julia> df1 = rdb("IMF", "WEO:2019-10", query = "France current account balance percent");

julia> df2 = rdb("IMF", "WEO:2019-10", query = "current account balance percent");


## By api_link
julia> df1 = rdb(api_link = "https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22indicator%22%3A%5B%22IC.REG.PROC.FE.NO%22%5D%7D&q=Doing%20Business&observations=1&format=json&align_periods=1&offset=0&facets=0");
# or
julia> df2 = rdb("https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22indicator%22%3A%5B%22IC.REG.PROC.FE.NO%22%5D%7D&q=Doing%20Business&observations=1&format=json&align_periods=1&offset=0&facets=0");


## Use proxy with curl
julia> h = Dict(:proxy => "http://<proxy>:<port>");

julia> DBnomics.options("curl_config", h);
julia> df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
# or
julia> df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN", curl_config = h);

# Regarding the functioning of HTTP.jl, you might need to modify another option
# It will change the url from https:// to http://
# (https://github.com/JuliaWeb/HTTP.jl/pull/390)
julia> DBnomics.options("secure", false);


## Use readlines and download
julia> DBnomics.options("use_readlines", true);
julia> df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
# or
julia> df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN", use_readlines = true);


## Apply a filter to the series
# One filter
julia> filters = Dict(:code => "interpolate", :parameters => Dict(:frequency => "daily", :method => "spline"));
julia> df1 = rdb(ids = ["IMF/WEO:2019-10/ABW.BCA.us_dollars", "IMF/WEO:2019-10/ABW.NGDPD.us_dollars"], filters = filters);

# For two filters
julia> filter1 = Dict(:code => "interpolate", :parameters => Dict(:frequency => "quarterly", :method => "spline"));
julia> filter2 = Dict(:code => "aggregate", :parameters => Dict(:frequency => "annual", :method => "average"));
julia> filters = (filter1, filter2);
julia> df1 = rdb(ids = ["IMF/WEO:2019-10/ABW.BCA.us_dollars", "IMF/WEO:2019-10/ABW.NGDPD.us_dollars"], filters = filters);

julia> filter1 = Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "linear"));
julia> filter2 = Dict(:code => "x13", :parameters => nothing);
julia> filters = (filter1, filter2);
julia> df1 = rdb("ECB/EXR/A.AUD.EUR.SP00.A", filters = filters);
```
"""
function rdb(
    provider_code::Union{Array, String, Symbol, Nothing} = nothing,
    dataset_code::Union{String, Symbol, Nothing} = nothing,
    mask_arg::Union{String, Nothing} = nothing;
    ids::Union{Array, String, Nothing} = nothing,
    dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing,
    mask::Union{String, Nothing} = nothing,
    query::Union{String, Nothing} = nothing,
    api_link::Union{String, Nothing} = nothing,
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    filters::Union{Nothing, Dict, Tuple} = DBnomics.filters,
    kwargs...
)
    # Setting API url
    api_base_url::String = DBnomics.api_base_url
    # Setting API version
    api_version::Int64 = DBnomics.api_version
    # Setting API metadata
    metadata::Bool = DBnomics.metadata
    metadata_str::String = metadata ? "?" : ("?metadata=" * string(Int64(metadata)) * "&")
    
    api_base_url = api_base_url * "/v" * string(api_version) * "/series"
    
    # Checking arguments
    provider_code_null::Bool = isa(provider_code, Nothing)
    provider_code_not_null::Bool = !provider_code_null
    
    dataset_code_null::Bool = isa(dataset_code, Nothing)
    dataset_code_not_null::Bool = !dataset_code_null
    
    dimensions_null::Bool = isa(dimensions, Nothing)
    dimensions_not_null::Bool = !dimensions_null
    
    mask_null::Bool = isa(mask, Nothing)
    mask_not_null::Bool = !mask_null
    
    ids_null::Bool = isa(ids, Nothing)
    ids_not_null::Bool = !ids_null
    
    mask_arg_null::Bool = isa(mask_arg, Nothing)
    mask_arg_not_null::Bool = !mask_arg_null
    
    query_null::Bool = isa(query, Nothing)
    query_not_null::Bool = !query_null
    
    api_link_null::Bool = isa(api_link, Nothing)
    api_link_not_null::Bool = !api_link_null
    
    provider_code = isa(provider_code, Symbol) ? string(provider_code) : provider_code
    dataset_code = isa(dataset_code, Symbol) ? string(dataset_code) : dataset_code

    # provider_code is actually api_link
    if (
        provider_code_not_null && dataset_code_null &&
        dimensions_null && mask_null && ids_null && mask_arg_null &&
        query_null && api_link_null && DBnomics.rdb_no_arg
    )
        if isa(provider_code, String)
            if occursin(r"^http(s)*://", lowercase(provider_code))
                api_link = provider_code
                provider_code = nothing
                
                provider_code_null = true
                provider_code_not_null = !provider_code_null
                
                api_link_null = false
                api_link_not_null = !api_link_null
            end
        end
    end
    
    # By api_link
    if api_link_not_null
        return DBnomics.dot_rdb(
            api_link;
            use_readlines = use_readlines, curl_config = curl_config,
            filters = filters, kwargs...
        )
    end
    
    # provider_code is actually ids
    if (
        provider_code_not_null && dataset_code_null &&
        dimensions_null && mask_null && ids_null && mask_arg_null &&
        query_null && api_link_null && DBnomics.rdb_no_arg
    )
        ids = provider_code
        provider_code = nothing
        
        provider_code_null = true
        provider_code_not_null = !provider_code_null
        
        ids_null = false
        ids_not_null = !ids_null
    end
    
    # mask_arg is actually mask
    if (
        provider_code_not_null && dataset_code_not_null &&
        mask_arg_not_null && dimensions_null && mask_null &&
        ids_null && query_null && api_link_null && DBnomics.rdb_no_arg
    )
        mask = mask_arg
        mask_arg = nothing
        
        mask_null = false
        mask_not_null = !mask_null
        
        mask_arg_null = true
        mask_arg_not_null = !mask_arg_null
    end
    
    # By dimensions
    if dimensions_not_null
        if provider_code_null || dataset_code_null
            error(
                "When you filter with 'dimensions', you must specifiy " *
                "'provider_code' and 'dataset_code' as arguments of the " *
                "function."
            )
        end
        
        dimensions = to_json_if_dict_namedtuple(dimensions)
        
        link = api_base_url * "/" * provider_code * "/" * dataset_code *
            metadata_str * "&observations=1&dimensions=" * dimensions
        
        return DBnomics.dot_rdb(
            link;
            use_readlines = use_readlines, curl_config = curl_config,
            filters = filters, kwargs...
        )
    end
    
    # By mask
    if mask_not_null
        if provider_code_null || dataset_code_null
            error(
                "When you filter with 'mask', you must specifiy " *
                "'provider_code' and 'dataset_code' as arguments of the " *
                "function."
            )
        end
        
        link = api_base_url * "/" * provider_code * "/" * dataset_code *
            "/" * mask * metadata_str * "&observations=1"
        
        return DBnomics.dot_rdb(
            link;
            use_readlines = use_readlines, curl_config = curl_config,
            filters = filters, kwargs...
        )
    end
    
    # By ids
    if ids_not_null
        if provider_code_not_null || dataset_code_not_null
            if DBnomics.verbose_warning
                @warn "When you filter with 'ids', " *
                    "'provider_code' and 'dataset_code' are not considered."
            end
        end
        
        if isa(ids, String)
            ids = [ids]
        end
        if !isa(ids, Array{String, 1})
            error("'ids' must be an array of strings.")
        end
        if length(ids) <= 0
            error("'ids' is empty.")
        end
        
        link = api_base_url * metadata_str * "&observations=1&series_ids=" *
            reduce((u, w) -> u * "," * w, ids)
        
        return DBnomics.dot_rdb(
            link;
            use_readlines = use_readlines, curl_config = curl_config,
            filters = filters, kwargs...
        )
    end
    
    # By query
    if query_not_null
        if provider_code_null || dataset_code_null
            error(
                "When you filter with a 'query', you must specifiy " *
                "'provider_code' and 'dataset_code' as arguments of the " *
                "function."
            )
        end
        
        if DBnomics.verbose_warning
            if query == ""
                @warn "Your 'query' is empty, the entire dataset " *
                    provider_code * "/" * dataset_code *
                    " will be downloaded. It can be long !"
            end
        end
        
        link = api_base_url * "/" * provider_code * "/" * dataset_code *
          metadata_str * "&q=" * HTTP.escapeuri(query) * "&observations=1"
        
        return DBnomics.dot_rdb(
            link;
            use_readlines = use_readlines, curl_config = curl_config,
            filters = filters, kwargs...
        )
    end
    
    error("Please provide correct 'dimensions', 'mask', 'ids' or 'query'.")
end
