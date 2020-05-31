"""
    rdb_series(
        provider_code::Union{Nothing, String, Array} = nothing,
        dataset_code::Union{Nothing, String, Array} = nothing;
        dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing,
        query::Union{String, Nothing} = nothing,
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        simplify::Bool = false,
        kwargs...
    )

`rdb_series` downloads the list of series for available datasets of
a selection of providers from [DBnomics](https://db.nomics.world/).

We warn the user that this function can be (very) long to execute. We remind that DBnomics
requests data from 63 providers to retrieve 21675 datasets for a total of approximately
720 millions series.

By default, the function returns a nested `Dict` of `DataFrame`s
containing the series of datasets for providers from
[DBnomics](https://db.nomics.world/).

# Arguments
- `provider_code::Union{Nothing, String, Array} = nothing`: DBnomics code of one or multiple
  providers. If `nothing`, the providers are firstly dowloaded with the function `rdb_providers`
  and then the available datasets are requested.
- `dataset_code::Union{Nothing, String, Array} = nothing`: DBnomics code 
  of one or multiple datasets of a provider. If `nothing`, the datasets 
  codes are dowloaded with the function `rdb_datasets` and then 
  the series are requested.
- `dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing`: DBnomics code of one
  or several dimensions in the specified provider and dataset. If it is a `Dict` or a
  `NamedTuple`, then then function `json` (from the package **JSON.jl**) is applied to
  generate the json object.
- `query::Union{String, Nothing} = nothing`: A query to filter/select series from a
  provider's dataset.
- `use_readlines::Bool = DBnomics.use_readlines`: (default `false`) If `true`, then
  the data are requested and read with the function `readlines`.
- `curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config`: (default `nothing`)
  If not `nothing`, it is used to configure a proxy connection. This
  configuration is passed to the keyword arguments of the function `HTTP.get` of
  the package **HTTP.jl**.
- `simplify::Bool = false`: If `true`, when the dimensions are requested for only one provider
  and one dataset then a `Dict` of `DataFrame`s is returned, not a nested `Dict` of `DataFrame`s.
- `kwargs...`: Keyword arguments to be passed to `HTTP.get`.

# Examples
```jldoctest
julia> rdb_series("IMF", "WEO")

# With dimensions
julia> rdb_series("IMF", "WEO", dimensions = Dict(Symbol("weo-country") => "AGO"))
julia> rdb_series("IMF", "WEO", dimensions = Dict(Symbol("weo-subject") => "NGDP_RPCH"), simplify = true)

# With query
julia> rdb_series("IMF", "WEO", query = "ARE")
julia> rdb_series("IMF", ["WEO", "WEOAGG"], query = "NGDP_RPCH")

julia> using ProgressMeter
julia> rdb_series("IMF", "WEO")

julia> rdb_series("IMF", "WEO", use_readlines = true)

julia> rdb_series("IMF", "WEO", curl_config = Dict(:proxy => "http://<proxy>:<port>"))

# Regarding the functioning of HTTP.jl, you might need to modify another option
# It will change the url from https:// to http://
# (https://github.com/JuliaWeb/HTTP.jl/pull/390)
julia> DBnomics.options("secure", false);
```
"""
function rdb_series(
    provider_code::Union{Nothing, String, Array} = nothing,
    dataset_code::Union{Nothing, String, Array} = nothing;
    dimensions::Union{Dict, NamedTuple, String, Nothing} = nothing,
    query::Union{String, Nothing} = nothing,
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    simplify::Bool = false,
    kwargs...
)
    if isa(provider_code, Nothing) && !isa(dataset_code, Nothing)
        error("If you give datasets codes, please give also a provider code.")
    end
    
    if isa(provider_code, Nothing)
        # All providers
        provider_code = rdb_providers(
            true;
            use_readLines = use_readlines, curl_config = curl_config, kwargs...
        )
    elseif isa(provider_code, String)
        provider_code = [provider_code]
    end
    
    if isa(dataset_code, Nothing)
        dataset_code = rdb_datasets(
            provider_code;
            use_readlines = use_readlines, curl_config = curl_config, kwargs...
        )
        dataset_code = extract_code(dataset_code)
    else
        dataset_code = isa(dataset_code, String) ? [dataset_code] : dataset_code
        dataset_code = Dict(Symbol(provider_code[1]) => dataset_code)
    end
    
    query_null::Bool = isa(query, Nothing)
    query_not_null::Bool = !query_null
    
    dimensions_null::Bool = isa(dimensions, Nothing)
    dimensions_not_null::Bool = !dimensions_null
    if dimensions_not_null
        dimensions = to_json_if_dict_namedtuple(dimensions)
    end
    
    if isa(curl_config, Nothing)
        curl_config = kwargs
    end
    
    api_base_url::String = DBnomics.api_base_url
    api_version::Int64 = DBnomics.api_version
    
    # Fetching all datasets
    series = map(provider_code) do pc     
        tmp_ser = map(dataset_code[Symbol(pc)]) do dc
            try
                api_link = api_base_url * "/v" * string(api_version) * "/series/" * pc * "/" * dc
                        
                if query_not_null
                    api_link = api_link * "?q=" * HTTP.escapeuri(query)
                end
                
                if dimensions_not_null
                    api_link = api_link * (occursin(r"\?", api_link) ? "&" : "?") *
                        "dimensions=" * dimensions
                end
                
                DBlist = get_data(api_link, use_readlines, 0, nothing, nothing; curl_config...)
                num_found = DBlist["series"]["num_found"]
                limit = DBlist["series"]["limit"]
                
                if DBnomics.only_number_series
                    println(
                        "Downloading number of series for " * pc * "(" *
                            string(length(dataset_code[Symbol(pc)])) * ")/" * dc
                    )
                    return Dict(:Number_of_series => num_found)
                end
                
                DBdata = [
                    Dict(
                        :series_code => [DBlist["series"]["docs"][iseries]["series_code"]],
                        :series_name => [DBlist["series"]["docs"][iseries]["series_name"]]
                    )
                    for iseries in 1:length(DBlist["series"]["docs"])
                ]
                DBdata = concatenate_dict(DBdata)
                
                if num_found <= limit
                    if DBnomics.progress_bar_series
                        p = ProgressMeter.Progress(
                            1, 1,
                            "Downloading series for " * pc * "/" * dc * "..."
                        )
                        ProgressMeter.next!(p)
                    end
                else
                    DBdata0 = deepcopy(DBdata)
                    DBdata = nothing
                    
                    sequence = 1:Int(floor(num_found / limit))        
                    
                    if DBnomics.only_first_two
                        sequence = [sequence[1]]
                    end
                    
                    if DBnomics.progress_bar_series
                        p = ProgressMeter.Progress(
                            length(sequence), 1,
                            "Downloading series for " * pc * "/" * dc * "..."
                        )
                    end
                    
                    # Modifying link
                    if occursin(r"offset=", api_link)
                        api_link = replace(api_link, r"\&offset=[0-9]+" => "")
                        api_link = replace(api_link, r"\?offset=[0-9]+" => "")
                    end
                    sep = occursin(r"\?", api_link) ? "&" : "?"
                    
                    DBdata = map(sequence) do j
                        # Modifying link
                        tmp_api_link = api_link * sep * "offset=" * string(j * limit)
                        # Fetching data
                        DBlist = get_data(api_link, use_readlines, 0, nothing, nothing; curl_config...)
                        
                        if DBnomics.progress_bar_series
                            ProgressMeter.next!(p)
                        end
                        
                        # Extracting data
                        tmp_DBdata = [
                            Dict(
                                :series_code => [DBlist["series"]["docs"][iseries]["series_code"]],
                                :series_name => [DBlist["series"]["docs"][iseries]["series_name"]]
                            )
                            for iseries in 1:length(DBlist["series"]["docs"])
                        ]
                        concatenate_dict(tmp_DBdata)                        
                    end
                    DBdata = concatenate_dict(DBdata)
                    DBdata = concatenate_dict([DBdata0, DBdata])
                    DBdata0 = nothing
                end
                
                if DBnomics.progress_bar_series
                    ProgressMeter.finish!(p)
                end
                
                change_type!(DBdata)
                
                if !DBnomics.only_number_series
                    i_sort = [
                        findfirst(isequal(u), DBdata[:series_code])
                        for u in sort(unique(DBdata[:series_code]))
                    ]
                    push!(DBdata, :series_code => DBdata[:series_code][i_sort_tmp])
                    push!(DBdata, :series_name => DBdata[:series_name][i_sort_tmp])
                end
                
                DBdata
            catch
                nothing
            end
        end # tmp_ser
        
        tmp_ser = NamedTuple{Tuple(Symbol.(dataset_code[Symbol(pc)]))}(tmp_ser)
        tmp_ser = NamedTuple_to_Dict(tmp_ser)
        
        for k in keys(tmp_ser)
            if isa(tmp_ser[k], Nothing)
                pop!(tmp_ser, k)
            end
        end
        
        tmp_ser
    end # series
    
    series = NamedTuple{Tuple(Symbol.(provider_code))}(series)
    series = NamedTuple_to_Dict(series)
    
    for k in keys(series)
        if isa(series[k], Nothing)
            pop!(series, k)
        end
    end
    
    if length(series) <= 0
        @warn "Error when fetching the series codes."
        return nothing
    end
    
    result = Dict{Symbol, Dict}()
    for k1 in keys(series)
        push!(result, k1 => df_empty_dict())
        for k2 in keys(series[k1])
            push!(result[k1], k2 => df_return(series[k1][k2]))
            pop!(series[k1], k2)
        end
    end
    
    if simplify
        len = [length(result[u]) for u in ckeys(result)]
        if length(ckeys_string(result)) == 1 && len[1] == 1
            result = result[ckeys(result)[1]]
            return result[ckeys(result)[1]]
        end
    end
    
    result
end
