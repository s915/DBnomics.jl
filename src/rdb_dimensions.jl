"""
    rdb_dimensions(
        provider_code::Union{Nothing, String, Array} = nothing,
        dataset_code::Union{Nothing, String, Array} = nothing;
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        simplify::Bool = false,
        kwargs...
    )

`rdb_dimensions` downloads the list of dimensions (if they exist) for available datasets of
a selection of providers from [DBnomics](https://db.nomics.world/).

By default, the function returns a nested `Dict` of `DataFrame`s
containing the dimensions of datasets for providers from
[DBnomics](https://db.nomics.world/).

# Arguments
- `provider_code::Union{Nothing, String, Array} = nothing`: DBnomics code of one or multiple
  providers. If `nothing`, the providers are firstly dowloaded with the function `rdb_providers`
  and then the available datasets are requested.
- `dataset_code::Union{Nothing, String, Array} = nothing`: DBnomics code 
  of one or multiple datasets of a provider. If `nothing`, the datasets 
  codes are dowloaded with the function `rdb_datasets` and then 
  the dimensions are requested.
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
julia> rdb_dimensions("IMF", "WEO")

julia> rdb_dimensions("IMF", "WEO", simplify = true)

julia> rdb_dimensions("IMF")

# It is very long !
julia> using ProgressMeter
julia> rdb_dimensions()

julia> rdb_dimensions("IMF", "WEO", use_readlines = true)

julia> rdb_dimensions("IMF", "WEO", curl_config = Dict(:proxy => "http://<proxy>:<port>"))

# Regarding the functioning of HTTP.jl, you might need to modify another option
# It will change the url from https:// to http://
# (https://github.com/JuliaWeb/HTTP.jl/pull/390)
julia> DBnomics.options("secure", false);
```
"""
function rdb_dimensions(
    provider_code::Union{Nothing, String, Array} = nothing,
    dataset_code::Union{Nothing, String, Array} = nothing;
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    simplify::Bool = false,
    kwargs...
)
    if isa(provider_code, Nothing) && !isa(dataset_code, Nothing)
        error("If you give datasets codes, please give also a provider code.")
    end

    if !isa(provider_code, Nothing) && !isa(dataset_code, Nothing)
        if !isa(provider_code, String)
            if length(provider_code) > 1
                error("If you give datasets codes, please give only one provider code.")
            end
        end
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

    if isa(curl_config, Nothing)
        curl_config = kwargs
    end

    api_base_url::String = DBnomics.api_base_url
    api_version::Int64 = DBnomics.api_version
    
    # Fetching all datasets
    dimensions = map(provider_code) do pc
        if !(pc in ckeys_string(dataset_code))
            return nothing
        end

        if DBnomics.progress_bar_dimensions
            p = ProgressMeter.Progress(
                length(dataset_code[Symbol(pc)]), 1,
                "Downloading dimensions for " * pc * "..."
            )
        end
        
        tmp_dim = map(dataset_code[Symbol(pc)]) do dc
            try
                api_link::String = api_base_url * "/v" * string(api_version) *
                    "/datasets/" * pc * "/" * dc
                tmp = get_data(api_link, use_readlines, 0, nothing, nothing; curl_config...)
                
                tmp1 = try
                    tmp["datasets"]["docs"][1]["dimensions_labels"]
                catch
                    try
                        tmp["datasets"][pc * "/" * dc]["dimensions_labels"]
                    catch
                        nothing
                    end
                end

                if isa(tmp1, Nothing)
                    # Sometimes "dimensions_labels" is missing
                    tmp1 = Dict(:A => String[], :B => String[])
                else
                    tmp1 = Dict(:A => cvalues(tmp1), :B => ckeys(tmp1))
                    change_type!(tmp1)
                end

                tmp2 = try
                    tmp["datasets"]["docs"][1]["dimensions_values_labels"]
                catch
                    try
                        tmp["datasets"][pc * "/" * dc]["dimensions_values_labels"]
                    catch
                        nothing
                    end
                end
                change_type!(tmp2)
                if length(ckeys(tmp2)) <= 0
                    return nothing
                end
                
                tmp3 = map(1:length(ckeys(tmp2))) do inm
                    nm = ckeys(tmp2)[inm]
                    z = tmp2[nm]
                        
                    jnm = findall(isequal(nm), tmp1[:B])
                    if length(jnm) <= 0
                        nm2 = uppercasefirst(lowercase(nm))
                        if nm2 == nm
                            nm2 = uppercase(nm)
                        end
                    else
                        nm2 = tmp1[:A][jnm[1]]
                    end
                    Dict(
                        Symbol(nm) => [iz[1] for iz in z],
                        Symbol(nm2) => [iz[2] for iz in z]
                    )
                end
                
                if DBnomics.progress_bar_dimensions
                    ProgressMeter.next!(p)
                end
                
                tmp3 = NamedTuple{Tuple(Symbol.(ckeys(tmp2)))}(tmp3)
                NamedTuple_to_Dict(tmp3)
            catch
                nothing
            end
        end
        
        if DBnomics.progress_bar_dimensions
            ProgressMeter.finish!(p)
        end
        
        tmp_dim = NamedTuple{Tuple(Symbol.(dataset_code[Symbol(pc)]))}(tmp_dim)
        NamedTuple_to_Dict(tmp_dim)
    end # dimensions
    
    dimensions = NamedTuple{Tuple(Symbol.(provider_code))}(dimensions)
    dimensions = NamedTuple_to_Dict(dimensions)
    
    for k in keys(dimensions)
        if isa(dimensions[k], Nothing)
            pop!(dimensions, k)
        else
            if length(dimensions[k]) <= 0
                pop!(dimensions, k)
            else
                for l in keys(dimensions[k])
                    if isa(dimensions[k][l], Nothing)
                        pop!(dimensions[k], l)
                    end
                end
            end
        end
    end
    
    if length(dimensions) <= 0
        @warn "Error when fetching the datasets codes."
        return nothing
    end

    result = Dict{Symbol, Dict}()
    for k1 in keys(dimensions)
        push!(result, k1 => Dict{Symbol, Dict}())
        for k2 in keys(dimensions[k1])
            push!(result[k1], k2 => df_empty_dict())
            for k3 in keys(dimensions[k1][k2])
                push!(result[k1][k2], k3 => df_return(dimensions[k1][k2][k3]))
                pop!(dimensions[k1][k2], k3)
            end
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
