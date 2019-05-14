"""
    rdb_last_updates(
        all_updates::Bool = false;
        use_readlines::Bool = DBnomics.use_readlines,
        curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
        kwargs...
    )

`rdb_last_updates` downloads informations about the last updates from
[DBnomics](https://db.nomics.world/)

By default, the function returns a `DataFrame`
containing the last 100 updates from
[DBnomics](https://db.nomics.world/) with additional informations.

# Arguments
- `all_updates::Bool = false`: If `true`, then the full dataset of the last updates
  is retrieved.
- `use_readlines::Bool = DBnomics.use_readlines`: (default `false`) If `true`, then
  the data are requested and read with the function `readlines`.
- `curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config`: (default `nothing`)
  If not `nothing`, it is used to configure a proxy connection. This
  configuration is passed to the keyword arguments of the function `HTTP.get` of
  the package *HTTP*.
- `kwargs...`: Keyword arguments to be passed to `HTTP.get`.

# Examples
```jldoctest
julia> rdb_last_updates()

julia> rdb_last_updates(true)

julia> rdb_last_updates(use_readlines = true)

julia> rdb_last_updates(curl_config = Dict(:proxy => "<proxy>"))

julia> rdb_last_updates(proxy = "<proxy>")
```
"""
function rdb_last_updates(
    all_updates::Bool = false;
    use_readlines::Bool = DBnomics.use_readlines,
    curl_config::Union{Nothing, Dict, NamedTuple} = DBnomics.curl_config,
    kwargs...
)
    api_base_url = DBnomics.api_base_url
    api_version = DBnomics.api_version

    api_link = api_base_url * "/v" * string(api_version) * "/last-updates"

    if isa(curl_config, Nothing)
        curl_config = kwargs
    end

    updates = get_data(api_link, use_readlines, 0; curl_config...)

    num_found = updates["datasets"]["num_found"]
    limit = updates["datasets"]["limit"]

    iter = 0
    if all_updates
        iter = 0:Int(floor(num_found / limit))
    end

    updates = map(iter) do u
        api_link = api_base_url * "/v" * string(api_version) *
            "/last-updates?datasets.offset=" * string(Int(u * limit))
        tmp_up = get_data(api_link, use_readlines, 0; curl_config...)
        tmp_up = tmp_up["datasets"]["docs"]
        tmp_up = to_dataframe.(tmp_up)
        tmp_up = concatenate_data(tmp_up)
        change_type!(tmp_up)
        transform_date_timestamp!(tmp_up)
        tmp_up
    end

    if isa(updates, Array{DataFrame, 1})
        updates = concatenate_data(updates)
        change_type!(updates)
    end

    updates
end
