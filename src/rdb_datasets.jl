"""
    rdb_datasets(
        provider_code::Union{Nothing, String, Array} = nothing;
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        simplify::Bool = false,
        kwargs...
    )

`rdb_datasets` downloads the list of available datasets for a selection of providers
(or all of them) from [DBnomics](https://db.nomics.world/).

By default, the function returns a `Dict` of `DataFrame`s
containing the datasets of the providers from
[DBnomics](https://db.nomics.world/).

# Arguments
- `provider_code::Union{Nothing, String, Array} = nothing`: DBnomics code of one or multiple
  providers. If `nothing`, the providers are firstly dowloaded with the function `rdb_providers`
  and then the available datasets are requested.
- `use_readlines::Bool = DBnomics.use_readlines`: (default `false`) If `true`, then
  the data are requested and read with the function `readlines`.
- `curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config`: (default `nothing`)
  If not `nothing`, it is used to configure a proxy connection. This
  configuration is passed to the keyword arguments of the function `HTTP.get` of
  the package **HTTP.jl**.
- `simplify::Bool = false`: If `true`, when the datasets are requested for only one provider
  then a `DataFrame` is returned, not a `Dict` of `DataFrame`s.
- `kwargs...`: Keyword arguments to be passed to `HTTP.get`.

# Examples
```jldoctest
julia> rdb_datasets("IMF")

julia> rdb_datasets("IMF", simplify = true)

julia> rdb_datasets(["IMF", "BDF"])

julia> using ProgressMeter
julia> rdb_datasets()

julia> rdb_datasets("IMF", use_readlines = true)

julia> rdb_datasets("IMF", curl_config = Dict(:proxy => "http://<proxy>:<port>"))

# Regarding the functioning of HTTP.jl, you might need to modify another option
# It will change the url from https:// to http://
# (https://github.com/JuliaWeb/HTTP.jl/pull/390)
julia> DBnomics.options("secure", false);
```
"""
function rdb_datasets(
    provider_code::Union{Nothing, String, Array} = nothing;
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    simplify::Bool = false,
    kwargs...
)
    if isa(provider_code, Nothing)
        # All providers
        provider_code = rdb_providers(
          true;
          use_readLines = use_readlines, curl_config = curl_config, kwargs...
        )
    elseif isa(provider_code, String)
        provider_code = [provider_code]
    end
    
    if isa(curl_config, Nothing)
        curl_config = kwargs
    end
    
    api_base_url::String = DBnomics.api_base_url
    api_version::Int64 = DBnomics.api_version
    
    if DBnomics.progress_bar_datasets
        p = ProgressMeter.Progress(length(provider_code), 1, "Downloading datasets...")
    end
    
    datasets = map(provider_code) do pc
        try
            api_link::String = api_base_url * "/v" * string(api_version) * "/providers/" * pc
            
            tmp = get_data(api_link, use_readlines, 0, nothing, nothing; curl_config...)
            tmp = extract_children(tmp["category_tree"])
            tmp = extract_dict(tmp)
            tmp = vcat(tmp...)
            tmp = Dict(
                :name => [get(x, "name", missing) for x in tmp],
                :code => [get(x, "code", missing) for x in tmp]
            )
            
            i_sort_tmp = [findfirst(isequal(u), tmp[:code]) for u in sort(unique(tmp[:code]))]
            push!(tmp, :name => tmp[:name][i_sort_tmp])
            push!(tmp, :code => tmp[:code][i_sort_tmp])
            
            if DBnomics.progress_bar_datasets
                ProgressMeter.next!(p)
            end
            
            tmp
        catch
            nothing
        end
    end
    
    if DBnomics.progress_bar_datasets
        ProgressMeter.finish!(p)
    end
    
    datasets = NamedTuple{Tuple(Symbol.(provider_code))}(datasets)
    datasets = NamedTuple_to_Dict(datasets)
    
    for k in keys(datasets)
        if isa(datasets[k], Nothing)
            pop!(datasets, k)
        end
    end
    
    if length(datasets) <= 0
        @warn "Error when fetching the datasets codes."
        return nothing
    end
    
    result = df_empty_dict()
    for k in keys(datasets)
        change_type!(datasets[k])
        push!(result, k => df_return(datasets[k]))
        pop!(datasets, k)
    end
    
    if simplify
        if length(result) == 1
            result = result[ckeys(result)[1]]
        end
    end
    
    result
end
