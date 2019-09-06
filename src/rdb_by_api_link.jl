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
  configuration is passed to the keyword arguments of the function `HTTP.get` of
  the package *HTTP*.
- `filters::Union{Nothing, Dict, Tuple} = DBnomics.filters`: (default `nothing`)
  This argument must be a `Dict` for one filter because the function `json` of the
  package *JSON* is used before sending the request to the server. For multiple
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
julia> h = Dict(:proxy => "<proxy>", :proxyport => <port>, :proxyusername => "<username>", :proxypassword => "<password>");

julia> DBnomics.options("curl_config", h);
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX");
# or
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series?observations=1&series_ids=AMECO/ZUTN/EA19.1.0.0.0.ZUTN,IMF/CPI/A.AT.PCPIT_IX", curl_config = h);


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
julia> filters = (Dict(:code => "interpolate", :parameters => Dict(:frequency => "quarterly", :method => "spline")), Dict(:code => "aggregate", :parameters => Dict(:frequency => "annual", :method => "average")));
julia> df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series/IMF/WEO/ABW.BCA?observations=1", filters = filters);

julia> filters = (Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "linear")), Dict(:code => "x13", :parameters => nothing));
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
    if isa(curl_config, Nothing)
        curl_config = kwargs
    end

    # Checking 'filters'
    if !isa(filters, Nothing)
        check_filter = filter_type(filters)
        if check_filter == "ko"
            error(
                "If only one filter is applied then 'filters' must be a Dict " *
                "with two keys : 'code' and 'parameters'." *
                "\n" *
                "'code' is a character string and 'parameters' is nothing " *
                "or a Dict ('frequency' and 'method')." *
                "\n" *
                "For more informations, visit <https://editor.nomics.world/filters>.",
                "\n" *
                "If multiple filters are applied then 'filters' must be a Tuple " *
                "of valid filters."
            )
        end
    
        if use_readlines
            @warn "When applying filters, the HTTP functions must be used." *
                "\n" *
                "As a consequence, 'use_readlines' is set to false."
            use_readlines = false
        end
    end

    DBdata = get_data(api_link, use_readlines, 0, nothing, nothing; curl_config...)

    api_version = DBdata["_meta"]["version"]
    
    num_found = DBdata["series"]["num_found"]
    limit = DBdata["series"]["limit"]

    # Additional informations to translate geo, freq, ...
    if !DBnomics.translate_codes
        additional_geo_column = additional_geo_mapping = nothing
    else
        additional_geo_column = get_geo_colname(DBdata)
        additional_geo_mapping = get_geo_names(DBdata, additional_geo_column)
        remove_provider!(additional_geo_column)
        # Check coherence
        if !isa(additional_geo_column, Nothing) & !isa(additional_geo_mapping, Nothing)
            if length(additional_geo_column) != length(additional_geo_mapping)
                additional_geo_column = additional_geo_mapping = nothing
            end
        end
    end

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
            tmp_up = get_data(link, use_readlines, 0, nothing, nothing; curl_config...)
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

    # DBnomics editor
    if !isa(filters, Nothing)
        if !isa(filters, Tuple)
            filters = (filters,)
        end

        # Filters are applied by 'series_code'
        if DBnomics.DataFrames019
            codes = unique(DBdata[:, :series_code])
        else
            codes = unique(DBdata[!, :series_code])
        end

        DBlist = map(1:length(codes)) do u
            x = codes[u]
            tmpdata = filter(row -> row.series_code == x, DBdata)

            # 'series' for the POST request
            if DBnomics.DataFrames019
                series = Dict(
                    :frequency => unique(tmpdata[:, Symbol("@frequency")])[1],
                    :period_start_day => tmpdata[:, :period],
                    :value => tmpdata[:, :value]
                )
            else
                series = Dict(
                    :frequency => unique(tmpdata[!, Symbol("@frequency")])[1],
                    :period_start_day => tmpdata[!, :period],
                    :value => tmpdata[!, :value]
                )
            end

            # POST request header
            headers = [
              "Content-Type" => "application/json", 
              "Accept" => "application/json"
            ]

            # POST request body
            body = JSON.json((filters = filters, series = (series,)))
            body = replace(body, "parameters\":null" => "parameters\":{}")
            body = replace(body, "null" => "\"NA\"")

            # Editor url
            editor_link = DBnomics.editor_base_url * "/api/v" *
              string(DBnomics.editor_version) * "/apply"

            request = get_data(editor_link, false, 0, headers, body; curl_config...)
            request = to_dataframe(request["filter_results"][1]["series"])
            change_type!(request)
            transform_date_timestamp!(request)

            # Some columns from the original dataset will be replaced by the
            # filtered dataset
            remove_columns!(
              tmpdata,
              ["@frequency", "original_period", "period", "value", "indexed_at"]
            )
            if !isa(additional_geo_column, Nothing)
                try
                    cols_to_remove = map(u -> u[2], additional_geo_column)
                    remove_columns!(tmpdata, cols_to_remove)
                catch
                end
            end
            remove_columns!(tmpdata, "^observation", true)
            # The aim is to keep only unique informations
            tmpdata = unique(tmpdata)
            if nrow(tmpdata) > 1
                reduce_to_one!(tmpdata)
                tmpdata = unique(tmpdata)
            end

            # Entire dataset with replaced columns
            tmpdata = repeat_df([tmpdata], nrow(request))
            tmpdata = reduce(hcat, tmpdata)

            [tmpdata request]
        end

        DBlist = reduce(vcat, DBlist)

        # Add filtered suffix
        if DBnomics.DataFrames019
            DBlist[:, :series_code] = DBlist[:, :series_code] .* "_filtered"
            DBlist[:, :series_name] = DBlist[:, :series_name] .* "(filtered)"
        else
            DBlist[!, :series_code] = DBlist[!, :series_code] .* "_filtered"
            DBlist[!, :series_name] = DBlist[!, :series_name] .* "(filtered)"
        end

        # We rename the column 'frequency'
        try
            freqcol = string.(names(DBdata))
            freqcol = freqcol[occursin.(Ref(r"^[@]*frequency$"), freqcol)]
            freqcol = freqcol[1]
            freqcol = Symbol(freqcol)
            rename!(DBlist, :frequency => freqcol)
        catch
        end

        try
            rename!(DBlist, :period => :original_period)
        catch
            error(
                "The retrieved dataset doesn't have a column named 'period', " *
                "it's not normal please check <db.nomics.world>."
            )
        end
        
        # In case of different types, the type of the column 'original_period'
        # is set to 'character'
        if DBnomics.DataFrames019
            type_DBdata_string = isa(DBdata[:, :original_period], Array{String,1})
            type_DBlist_string = isa(DBlist[:, :original_period], Array{String,1})
            if type_DBdata_string & !type_DBlist_string
                DBlist[:, :original_period] = string.(DBlist[:, :original_period])
            end
            if !type_DBdata_string & type_DBlist_string
                DBdata[:, :original_period] = string.(DBdata[:, :original_period])
            end
        else
            type_DBdata_string = isa(DBdata[!, :original_period], Array{String,1})
            type_DBlist_string = isa(DBlist[!, :original_period], Array{String,1})
            if type_DBdata_string & !type_DBlist_string
                DBlist[!, :original_period] = string.(DBlist[!, :original_period])
            end
            if !type_DBdata_string & type_DBlist_string
                DBdata[!, :original_period] = string.(DBdata[!, :original_period])
            end
        end

        try
            rename!(DBlist, :period_start_day => :period)
        catch
          error(
              "The retrieved dataset doesn't have a column named " *
              "'period_start_day', it's not normal please check <db.nomics.world>."
          )
        end

        # Add boolean to distinct be filtered and non-filtered series
        if DBnomics.DataFrames019
            DBdata[:, :filtered] = false
            DBlist[:, :filtered] = true
        else
            DBdata[!, :filtered] .= false
            DBlist[!, :filtered] .= true
        end
    
        DBdata = [DBdata, DBlist]
        DBdata = reduce(concatenate_data, DBdata)
    end

    # Additional informations translations
    if !isa(additional_geo_column, Nothing) & !isa(additional_geo_mapping, Nothing)
        for i = 1:length(additional_geo_mapping)
            addcol = additional_geo_column[i][3]
            suffix = ""
            if Symbol(addcol) in names(DBdata)
                suffix = "_add"
                newcol = addcol * suffix
                rename!(additional_geo_mapping[i], Symbol(addcol) => Symbol(newcol))
            end

            DBdata = join(
                DBdata, additional_geo_mapping[i],
                on = Symbol.(["dataset_code", additional_geo_column[i][2]]),
                kind = :left
            )

            if suffix != ""
                DBdata[Symbol(addcol)] = ifelse.(
                    isa.(DBdata[Symbol(newcol)], Missing),
                    DBdata[Symbol(addcol)],
                    DBdata[Symbol(newcol)]
                )
                df_delete_col!(DBdata, Symbol(newcol))
            end
        end
    end

    # We reorder the columns by their names
    permutecols!(
        DBdata,
        Symbol.(sort(string.(names(DBdata)), by = lowercase))
    )

    DBdata
end
