# printDT
function printDT(x::DataFrames.DataFrame, n::Union{Nothing, Int64} = nothing)
    if nrow(x) <= 10
        if isa(n, Nothing)
            x[selectop, :_row_] = 1:nrow(x)
        else
            x[selectop, :_row_] = vcat(1:5, (n - 4):n)
        end

        x = x[selectop, [ncol(x); 1:(ncol(x) - 1)]]

        show(x, allcols = true)

        df_delete_col!(x, :_row_)
        nothing
    else
        # y = [first(x, 5); last(x, 5)]
        y = [x[1:5,:]; x[(end - 4):end,:]]
        printDT(y, nrow(x))
    end
end

#-------------------------------------------------------------------------------
# repeat_df
function repeat_df(x::Array{DataFrames.DataFrame, 1}, n::Int64) 
    repeat.(x, Ref(n))
end

#-------------------------------------------------------------------------------
# readurl
function readurl(x::String)
    content = readlines(download(x))
    if isa(content, Array)
        return content[1]
    end
    content
end

#-------------------------------------------------------------------------------
# response_ok
function response_ok(x)
    x.status == DBnomics.http_ok # 200
end

#-------------------------------------------------------------------------------
# concatenate_data
function concatenate_data(
    x::Union{DataFrames.DataFrame, Array},
    y::Union{DataFrames.DataFrame, Nothing} = nothing
)
    if isa(y, Nothing)
        return reduce(concatenate_data, x)
    end

    nm_x, nm_y = names.([x, y])

    allowmissing!.([x, y])

    add_x = setdiff(nm_y, nm_x)
    if length(add_x) > 0
        df_complete_missing!(x, add_x)
    end
    
    add_y = setdiff(nm_x, nm_y)
    if length(add_y) > 0
        df_complete_missing!(y, add_y)
    end
    
    [x; y[selectop, names(x)]]
end

#-------------------------------------------------------------------------------
# unlist
function unlist(arr)
    rst = Any[]
    grep(v) = for x in v
        if isa(x, Tuple) || isa(x, Array)
            grep(x) 
        else
            push!(rst, x)
        end
    end
    grep(arr)
    rst
end

#-------------------------------------------------------------------------------
# to_dataframe
function to_dataframe(x::Dict)
    # For 'observations_attributes'
    if haskey(x, "value")
        reflen = length(x["value"])
    elseif haskey(x, "name")
        reflen = length(x["name"])
    end

    col_array = Dict(string(k) => isa(v, Array) for (k, v) in x)
    col_array = filter_true(col_array)
    col_array = collect(keys(col_array))

    if length(col_array) > 0
        col_array = Dict(zip(col_array, map(u -> unlist(x[u]), col_array)))
        lens = Dict(string(k) => length(v) for (k, v) in col_array)
        
        for (k, v) in lens
            if v == 1
                delete!(x, k)
                x[k] = col_array[k][1] * ","
            elseif v == 2
                delete!(x, k)
                x[k] = col_array[k][1] * "," * col_array[k][2]
            elseif v == reflen + 1
                delete!(x, k)
                x[k] = col_array[k][1] .* "," .* col_array[k][2:end]
            elseif v != reflen
                delete!(x, k)
                x[k] = reduce((u, w) -> u * "," * w, unique(col_array[k]))
            end
        end
    end

    # Dict
    hasdict = Dict(string(k) => isa(v, Dict) for (k, v) in x)
    hasdict = [k for (k, v) in hasdict if v == true]

    if length(hasdict) <= 0
        return DataFrame(x)
    end

    intern_dicts = map(hasdict) do y
        intern_dict = DataFrame(x[y])
        delete!(x, y)
        intern_dict
    end

    x = DataFrame(x)
    
    intern_dicts = repeat_df(intern_dicts, nrow(x))
    intern_dicts = reduce(hcat, intern_dicts)

    [x intern_dicts]
end

#-------------------------------------------------------------------------------
# no_empty_char
function no_empty_char(x::Union{Missing, String, Array})
    if isa(x, Missing)
        return String[]
    end
    if isa(x, String)
        x = x == "" ? String[] : [x]
        return x
    end
    if isa(x, Array{Missing, 1})
        return String[]
    end
    if isa(x, Array{String, 1})
        return filter(y -> y != "", x)
    end
    if isa(x, Array{Union{Missing, String}, 1})
        x = filter(y -> !isa(y, Missing) && y != "", x)
        return convert(Array{String, 1}, x)
    end
end

#-------------------------------------------------------------------------------
# trim
function trim(x::Union{String, Array})
    x = rstrip.(x)
    lstrip.(x)
end

#-------------------------------------------------------------------------------
# timestamp_format
function timestamp_format(x::Union{Missing, String, Array}, y::Regex)
    x = no_empty_char(x)
    if length(x) <= 0
        return false
    end
    sum(occursin.(Ref(y), trim(x))) == length(x)
end

#-------------------------------------------------------------------------------
# to_timestamp
function to_timestamp(x::Union{Missing, String}, y::String)
    if isa(x, Missing)
        return missing
    end
    x = replace(x, r"Z{0,1}$" => "")
    x = Dates.DateTime(x, y)
    TimeZones.ZonedDateTime(x, DBnomics.timestamp_tz)
end

#-------------------------------------------------------------------------------
# date_format
function date_format(x::Union{Missing, String, Array})
    x = no_empty_char(x)
    if length(x) <= 0
        return false
    end
    sum(occursin.(Ref(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"), trim(x))) == length(x)
end

#-------------------------------------------------------------------------------
# to_date
function to_date(x::Union{Missing, String})
    if isa(x, Missing)
        missing
    end
    Dates.Date(x, "y-m-d")
end

#-------------------------------------------------------------------------------
# transform_date_timestamp!
function transform_date_timestamp!(DT::DataFrames.DataFrame)
    from_timestamp_format = [
      r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z{0,1}$",
      r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+Z{0,1}$",
      r"^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:blank:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$"
    ]

    to_timestamp_format = [
      "y-m-dTH:M:S",
      "y-m-dTH:M:S.s",
      "y-m-d H:M:S"
    ]

    for col in names(DT)
        x = DT[selectop, col]
        if isa(x, Array{String, 1}) || isa(x, Array{Union{Missing, String}, 1})
            if date_format(x)
                DT[selectop, col] = to_date.(x)
            end
            for i in 1:length(from_timestamp_format)
                if timestamp_format(x, from_timestamp_format[i])
                    DT[selectop, col] = to_timestamp.(x, Ref(to_timestamp_format[i]))
                end
            end
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# has_missing
function has_missing(x::Union{Missing, Any, Array})
    sum(isa.(x, Ref(Missing))) > 0
end

#-------------------------------------------------------------------------------
# has_numeric_NA
function has_numeric_NA(x::Union{Missing, Any, Array})
    try
        tmp_x = trim(string.(x))
        (
            sum(
                occursin.(Ref(r"^[0-9]*[[:blank:]]*[0-9]+\.*[0-9]*$"), tmp_x)
            ) > 0
        ) &&
        (sum(occursin.(Ref(r"^NA$"), tmp_x)) > 0)
    catch
        false
    end
end

#-------------------------------------------------------------------------------
# simplify_type
function simplify_type(x)
    if has_numeric_NA(x)
        x = convert(Array{Union{Missing, Any}, 1}, x)
        x = map(u -> u == "NA" ? missing : u, x)
        return simplify_type(x)
    end

    result = nothing

    if isa(x, Array{Union{Missing, Any}, 1})
        try
            if has_missing(x)
                result = convert(Array{Union{Missing, Int64}, 1}, x)
            else
                result = convert(Array{Int64, 1}, x)
            end
        catch
            try
                if has_missing(x)
                    result = convert(Array{Union{Missing, Float64}, 1}, x)
                else
                    result = convert(Array{Float64, 1}, x)
                end
            catch
                try
                    if has_missing(x)
                        result = convert(Array{Union{Missing, String}, 1}, x)
                    else
                        result = convert(Array{String, 1}, x)
                    end
                catch
                    result = x
                end
            end
        end
    elseif isa(x, Array{Any,1})
        try
            result = convert(Array{Int64,1}, x)
        catch
            try
                result = convert(Array{Float64,1}, x)
            catch
                try
                    result = convert(Array{String,1}, x)
                catch
                    result = x
                end
            end
        end
    else
        if has_missing(x)
            result = x
        else
            result = collect(skipmissing(x))
        end
    end

    result
end

#-------------------------------------------------------------------------------
# change_type!
function change_type!(DT::DataFrames.DataFrame)
    for col in names(DT)
        DT[selectop, col] = simplify_type(DT[selectop, col])
    end
    nothing
end

#-------------------------------------------------------------------------------
# elt_to_array
elt_to_array(x::Dict) = Dict(k => isa(v, Array) ? v : [v] for (k, v) in x)
elt_to_array(x::NamedTuple) = map(u -> isa(u, Array) ? u : [u], x)

#-------------------------------------------------------------------------------
# to_json_if_dict_namedtuple
to_json_if_dict_namedtuple(x::Dict) = JSON.json(elt_to_array(x))
to_json_if_dict_namedtuple(x::NamedTuple) = JSON.json(elt_to_array(x))
to_json_if_dict_namedtuple(x::String) = x

#-------------------------------------------------------------------------------
# get_data
function get_data(
    x::String, userl::Bool = false, frun::Int64 = 0,
    headers::Union{Nothing, Array{Pair{String,String},1}} = nothing,
    body::Union{Nothing, String} = nothing;
    curl_conf...
)
    if (frun > 0)
        sys_sleep = DBnomics.sleep_run
        sleep(sys_sleep)
    end
  
    try
        if userl
            # Only readLines
            try
                response = readurl(x)
                return JSON.parse(response)
            catch
                error("BAD REQUEST")
            end
        else
            try
                if !DBnomics.secure
                    x = replace(x, Regex("^https") => "http")
                end
                if !isa(headers, Nothing) & !isa(body, Nothing)
                    response = HTTP.post(x, headers, body; curl_conf...)
                else
                    response = HTTP.get(x; curl_conf...)    
                end
                if !response_ok(response)
                    error("The response is not <200 OK>.")
                end
                return JSON.parse(String(response.body))
            catch e
                rethrow(e)
            end
        end
    catch e
        try_run = DBnomics.try_run
        
        if userl
            if e == ErrorException("BAD REQUEST")
                try_run = -1
            end
        else
            if !response_ok(e)
                try_run = -1
            end
        end

        if (frun < try_run)
            get_data(x, userl, frun + 1, headers, body; curl_conf...)
        else
            rethrow(e)
        end
    end
end

#-------------------------------------------------------------------------------
# check_argument
function check_argument(
    x, name::String, dtype::Union{DataType, Array},
    len::Bool = true, n::Int64 = 1, not_nothing::Bool = true
)
    if not_nothing
        if isa(x, Nothing)
            error(name * " cannot by nothing.")
        end
    end
    if !isa(dtype, Array{DataType, 1})
        dtype = [dtype]
    end
    if sum(isa.(x, Ref(dtype))) <= 0
        error(
            name * " must be of Type '" *
            string(reduce((u, v) -> string(u) * "', '" * string(v), dtype)) *
            "'."
        )
    end
    if len
        if length(x) != n
            error(name * " must be of length" * string(n) * ".")
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# key_to_symbol
function key_to_symbol(x::Dict)
    Dict(Symbol(k) => v for (k, v) in x)
end

#-------------------------------------------------------------------------------
# value_to_array
function value_to_array(x::Dict)
    x = Dict(k => isa(v, Array) ? v : [v] for (k, v) in x)

    len = Dict(k => length(v) for (k, v) in x)
    len = maximum(collect(values(len)))

    Dict(k => length(v) != len ? repeat(v, len) : v for (k, v) in x)
end

#-------------------------------------------------------------------------------
# retrieve
function retrieve(x::Dict, key_of_interest::Regex, output::Array = [])
    for (key, value) in x
        if occursin(key_of_interest, key)
            push!(output, value)
        end
        if isa(value, AbstractDict)
            retrieve(value, key_of_interest, output)
        end
    end
    output
end

#-------------------------------------------------------------------------------
# remove_provider
function remove_provider!(x::Array)
    map(x) do u
        u[1] = replace(u[1], r".*/" => "")
        u
    end
end

#-------------------------------------------------------------------------------
# get_geo_colname
function get_geo_colname(x::Dict)
    # First try with multiple datasets
    try
        subdict = x["datasets"]
        output = []
        for (key, value) in subdict
            res_dict = retrieve(subdict[key], r"^dimensions_label[s]*$")[1]
            for (k, v) in res_dict
                push!(output, [key, k ,v])
            end
        end
        output = unique(output)
        return output
    catch
        # Second try with only one dataset
        try
            subdict = x["dataset"]
            output = []
            keys_ = [string(key) for key in keys(subdict)]
            k = keys_[occursin.(Ref(r"^dimensions_label[s]*$"), keys_)]
            res_dict = subdict[k[1]]
            for (k, v) in res_dict
                push!(output, [subdict["code"], k ,v])
            end
            output = unique(output)
            return output
        catch
            return nothing
        end
    end
end

#-------------------------------------------------------------------------------
# get_geo_names
get_geo_names(x::Dict, colname::Nothing) = nothing
function get_geo_names(x::Dict, colname::Array)
    # First try with multiple datasets
    try
        result = map(colname) do u
            k = replace(u[1], r".*/" => "")

            z = retrieve(x["datasets"][u[1]], Regex("^" * u[2] * "\$"))
            z = to_dataframe(z[1])
            z = stack(z, names(z))
            z[selectop, :variable] = string.(z[selectop, :variable])
            names!(z, Symbol.(u[2:3]))
            
            insertcols!(z, 1, :dataset_code => k)
            z
        end
        return result
    catch
        # Second try with only one dataset
        try
            result = map(colname) do u
                subdict = x["dataset"]
                k = replace(u[1], r".*/" => "")

                keys_ = [string(key) for key in keys(subdict)]
                k_ = keys_[
                    occursin.(Ref(r"^dimensions_value[s]*_label[s]*$"), keys_)
                ]
            
                z = subdict[k_[1]][u[2]]
                z = to_dataframe(z)
                z = stack(z, names(z))
                z[selectop, :variable] = string.(z[selectop, :variable])
                names!(z, Symbol.(u[2:3]))
                
                insertcols!(z, 1, :dataset_code => k)
                z
            end
            return result
        catch
            return nothing
        end
    end
end

#-------------------------------------------------------------------------------
# filter_true
function filter_true(x::Dict) 
    filter(d -> (last(d) == true), x)
end

#-------------------------------------------------------------------------------
# filter_type
function filter_type(x::Tuple)
    test = try
        res = "ko"
        n = length(x)
        y = map(filter_ok, x)
        y = sum(y)
        if y == n
            res = "tuple"
        end
        res
    catch
        "ko"
    end

    test
end

function filter_type(x::Dict)
    # When Dict
    test = try
        res = filter_ok(x)
        if res
            res = "nottuple"
        else
            res = "ko"
        end
        res
    catch
        "ko"
    end
  
    test
end

#-------------------------------------------------------------------------------
# filter_ok
function filter_ok(x::Dict)
    try
        res = false
        nm1 = [string(key) for key in keys(x)]
        if isa(x[:parameters], Nothing)
            nm2 = nothing
        else
            nm2 = [string(key) for key in keys(x[:parameters])]
        end
        if nm1 == ["code", "parameters"]
            if isa(nm2, Nothing)
                res = true
            end
            if nm2 == ["frequency", "method"]
                res = true
            end
        end
        res
    catch
        false
    end
end

#-------------------------------------------------------------------------------
# remove_columns
function remove_columns!(
    DT::DataFrames.DataFrame, x::Union{String, Array{String, 1}, Regex},
    expr::Bool = false
)
    colnames = string.(names(DT))
    if expr
        cols = colnames[occursin.(Ref(x), colnames)]
    else
        if isa(x, String)
            x = [x]
        end
        cols = intersect(x, colnames)
    end
    if length(cols) > 0
        df_delete_col!(DT, Symbol.(x))
    end
    nothing
end

#-------------------------------------------------------------------------------
# reduce_to_one
function reduce_to_one!(DT::DataFrames.DataFrame)
    x = Dict{String, Int64}()

    for col in names(DT)
        push!(x, string(col) => length(unique(DT[selectop, col])))
    end

    x = filter(u -> u[2] > 1, x)
    if length(x)
        x = Symbol.(keys(x))
        df_delete_col!(DT, x)
    end
  
    nothing
end

#-------------------------------------------------------------------------------
# JuliaDBtable
# function JuliaDBtable(x::Dict)
#     table((; value_to_array(key_to_symbol(x))...))
# end
