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
        if isa(additional_geo_column, Nothing) | isa(additional_geo_mapping, Nothing)
            additional_geo_column = additional_geo_mapping = nothing
        else
            keep = []
            if length(additional_geo_column) != length(additional_geo_mapping)
                additional_geo_column = additional_geo_mapping = nothing
            else
                for iaddg in 1:length(additional_geo_column)
                    if !isa(additional_geo_column[iaddg], Nothing) & !isa(additional_geo_mapping[iaddg], Nothing)
                        push!(keep, iaddg)
                    end
                end
            end
            if length(keep) == 0
                additional_geo_column = additional_geo_mapping = nothing
            else
                additional_geo_column = additional_geo_column[keep]
                additional_geo_mapping = additional_geo_mapping[keep]
            end
        end
    end

    DBdata = DBdata["series"]["docs"]
    DBdata = to_dataframe.(DBdata)
    DBdata = reduce(concatenate_data, DBdata)
    original_values = DBdata[selectop, :value]
    change_type!(DBdata)
    original_value_to_string!(DBdata, original_values)
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
            original_values = tmp_up[selectop, :value]
            change_type!(tmp_up)
            original_value_to_string!(tmp_up, original_values)
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
        codes = unique(DBdata[selectop, :series_code])

        DBlist = map(1:length(codes)) do u
            x = codes[u]
            tmpdata = filter(row -> row.series_code == x, DBdata)

            # 'series' for the POST request
            series = Dict(
                :frequency => unique(tmpdata[selectop, Symbol("@frequency")])[1],
                :period_start_day => tmpdata[selectop, :period],
                :value => tmpdata[selectop, :value]
            )

            # POST request header
            headers = [
              "Content-Type" => "application/json", 
              "Accept" => "application/json"
            ]

            # POST request body
            body = JSON.json((filters = filters, series = (series,)))
            # null are not valid in json
            body = replace(body, "parameters\":null" => "parameters\":{}")
            body = replace(body, "null" => "\"NA\"")

            # Editor url
            editor_link = DBnomics.editor_base_url * "/api/v" *
              string(DBnomics.editor_version) * "/apply"

            request = get_data(editor_link, false, 0, headers, body; curl_config...)
            request = to_dataframe(request["filter_results"][1]["series"])
            original_values = request[selectop, :value]
            change_type!(request)
            original_value_to_string!(request, original_values)
            transform_date_timestamp!(request)

            # Some columns from the original dataset will be replaced by the
            # filtered dataset
            remove_columns!(
                tmpdata,
                [
                    "@frequency", "original_period", "period", "value",
                    "original_value", "indexed_at"
                ]
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
        DBlist[selectop, :series_code] = DBlist[selectop, :series_code] .* "_filtered"
        DBlist[selectop, :series_name] = DBlist[selectop, :series_name] .* "(filtered)"

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
        type_DBdata_string = isa(DBdata[selectop, :original_period], Array{String,1})
        type_DBlist_string = isa(DBlist[selectop, :original_period], Array{String,1})
        if type_DBdata_string & !type_DBlist_string
            DBlist[selectop, :original_period] = string.(DBlist[selectop, :original_period])
        end
        if !type_DBdata_string & type_DBlist_string
            DBdata[selectop, :original_period] = string.(DBdata[selectop, :original_period])
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
        DBdata[selectop, :filtered] = fill(false, nrow(DBdata))
        DBlist[selectop, :filtered] = fill(true, nrow(DBlist))
    
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
                DBdata[selectop, Symbol(addcol)] = ifelse.(
                    isa.(DBdata[selectop, Symbol(newcol)], Missing),
                    DBdata[selectop, Symbol(addcol)],
                    DBdata[selectop, Symbol(newcol)]
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
