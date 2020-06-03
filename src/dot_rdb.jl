function dot_rdb(
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

    api_version::String = DBdata["_meta"]["version"]
    num_found::Int64 = DBdata["series"]["num_found"]
    limit::Int64 = DBdata["series"]["limit"] 

    # Additional informations to translate geo, freq, ...
    additional_geo_column, additional_geo_mapping = additional_info(DBdata)

    DBdata = DBdata["series"]["docs"]
    DBdata = clean_data(DBdata, true)
    if isa(DBdata, Nothing)
        @warn "No data series found."
        return nothing
    end

    if num_found <= limit
        if DBnomics.progress_bar_dot
            p = ProgressMeter.Progress(1, 1, "Downloading data...")
            ProgressMeter.next!(p)
        end
    else
        iter::UnitRange{Int64} = 1:Int(floor(num_found / limit))

        if DBnomics.progress_bar_dot
            p = ProgressMeter.Progress(length(iter), 1, "Downloading data...")
        end

        if occursin(r"offset=", api_link)
            api_link = replace(api_link, r"\&offset=[0-9]+" => "")
            api_link = replace(api_link, r"\?offset=[0-9]+" => "")
        end
        sep::String = occursin(r"\?", api_link) ? "&" : "?"

        DBdata2 = map(iter) do u
            link::String = api_link * sep * "offset=" * string(Int(u * limit))
            tmp_up = get_data(link, use_readlines, 0, nothing, nothing; curl_config...)
            if DBnomics.progress_bar_dot
                ProgressMeter.next!(p)
            end
            tmp_up = tmp_up["series"]["docs"]
            clean_data(tmp_up, true)
        end

        DBdata = [DBdata]
        append!(DBdata, DBdata2)

        DBdata2 = nothing
    end

    if DBnomics.progress_bar_dot
        ProgressMeter.finish!(p)
    end

    if isa(DBdata, Array{Dict{Symbol, Array{T, 1} where T}, 1})
        DBdata = concatenate_dict(DBdata)
    end

    try
        rename_dict!(DBdata, :period, :original_period)
    catch
        error(
            "The retrieved dataset doesn't have a column named 'period', " *
            "it's not normal please check <db.nomics.world>."
        )
    end

    try
        rename_dict!(DBdata, :period_start_day, :period)
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
        codes = unique(DBdata[:series_code])

        DBlist = map(codes) do x
            tmpdata = select_dict(DBdata, :series_code, x)

            # 'series' for the POST request
            series = Dict(
                :frequency => unique(tmpdata[Symbol("@frequency")])[1],
                :period_start_day => tmpdata[:period],
                :value => tmpdata[:value]
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
            request = request["filter_results"][1]["series"]
            request = clean_data([request], true)

            # Some columns from the original dataset will be replaced by the
            # filtered dataset
            delete_dict!(
                tmpdata,
                [
                    Symbol("@frequency"), :original_period, :period, :value,
                    :original_value, :indexed_at
                ]
            )
            if !isa(additional_geo_column, Nothing)
                try
                    cols_to_remove = map(additional_geo_column) do u
                        replace(string(u[1]), r".*\|" => "")
                    end
                    delete_dict!(tmpdata, Symbol.(cols_to_remove))
                catch
                end
            end
            delete_dict!(tmpdata, "^observation", true)
            # The aim is to keep only unique informations
            tmpdata = Dict(k => unique(v) for (k, v) in tmpdata)
            check_length = (unique([length(v) for (k, v) in tmpdata]) != [1])
            if check_length
                reduce_to_one!(tmpdata)
                tmpdata = Dict(k => unique(v) for (k, v) in tmpdata)
            end

            # Entire dataset with replaced columns
            tmpdata = merge(request, tmpdata)

            concatenate_dict(tmpdata)
        end

        DBlist = concatenate_dict(DBlist)

        # Add filtered suffix
        DBlist[:series_code] = DBlist[:series_code] .* "_filtered"
        DBlist[:series_name] = DBlist[:series_name] .* "(filtered)"

        # We rename the column 'frequency'
        try
            freqcol = string.(ckeys(DBdata))
            freqcol = freqcol[occursin.(Ref(r"^[@]*frequency$"), freqcol)]
            freqcol = freqcol[1]
            freqcol = Symbol(freqcol)
            rename_dict!(DBlist, :frequency, freqcol)
        catch
        end

        try
            rename_dict!(DBlist, :period, :original_period)
        catch
            error(
                "The retrieved dataset doesn't have a column named 'period', " *
                "it's not normal please check <db.nomics.world>."
            )
        end
        
        # In case of different types, the type of the column 'original_period'
        # is set to 'character'
        type_DBdata_string = isa(DBdata[:original_period], Array{String,1})
        type_DBlist_string = isa(DBlist[:original_period], Array{String,1})
        if type_DBdata_string && !type_DBlist_string
            DBlist[:original_period] = string.(DBlist[:original_period])
        end
        if !type_DBdata_string && type_DBlist_string
            DBdata[:original_period] = string.(DBdata[:original_period])
        end

        try
            rename_dict!(DBlist, :period_start_day, :period)
        catch
            error(
                "The retrieved dataset doesn't have a column named " *
                "'period_start_day', it's not normal please check <db.nomics.world>."
            )
        end

        # Add boolean to distinct be filtered and non-filtered series
        DBdata[:filtered] = fill(false, length_element(DBdata))
        DBlist[:filtered] = fill(true, length_element(DBlist))
    
        DBdata = [DBdata, DBlist]
        DBdata = concatenate_dict(DBdata)
    end # filter

    # Additional informations translations
    DBdata = additional_info_add(DBdata, additional_geo_column, additional_geo_mapping)

    change_type!(DBdata, nothing, [:original_value])

    df_return(DBdata)
end
