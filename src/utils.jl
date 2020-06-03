# # key_to_symbol
# function key_to_symbol(x::Dict)::Dict
#     isa(ckeys(x), Array{Symbol, 1}) ? x : Dict(Symbol(k) => v for (k, v) in x)
# end

# key_to_symbol
function key_to_symbol(x::Dict)::Dict{Symbol, Any}
    y = Dict{Symbol, Any}()
    for k in keys(x)
        isa(k, String) ? push!(y, Symbol(k) => x[k]) : push!(y, k => x[k])
    end
    y
end

#-------------------------------------------------------------------------------
# value_to_array
function value_to_array(x::Dict)::Dict
    x = convert(Dict{Symbol, Any}, x)

    for k in keys(x)
        push!(x, k => isa(x[k], Array) ? x[k] : [x[k]])
    end

    len = [length(v) for (k, v) in x]
    len = maximum(len)

    for k in keys(x)
        push!(x, k => length(x[k]) != len ? repeat(x[k], len) : x[k])
    end

    convert(Dict{Symbol, Array{T,1} where T}, x)
end

#-------------------------------------------------------------------------------
# response_ok
response_ok(x)::Bool = x.status == DBnomics.http_ok # 200

#-------------------------------------------------------------------------------
# harmonize_dict
function harmonize_dict(x::Dict)::Dict{Symbol, Array{T,1} where T}
    x = key_to_symbol(x)
    x = value_to_array(x)
    convert(Dict{Symbol, Array{T,1} where T}, x)
end

#-------------------------------------------------------------------------------
# length_element
function length_element(x::Dict{Symbol, Array{T,1} where T})
    len = [length(v) for (k, v) in x]
    len = unique(len)
    length(len) == 1 ? len[1] : nothing
end

#-------------------------------------------------------------------------------
# no_empty_char
no_empty_char(x::Missing)::Array{String,1} = String[]
no_empty_char(x::Array{Missing, 1})::Array{String,1} = String[]
no_empty_char(x::String)::Array{String,1} = x == "" ? String[] : [x]
no_empty_char(x::Array{String, 1})::Array{String,1} = filter(u -> u != "", x)
function no_empty_char(x::Array{Union{Missing, String}, 1})::Array{String,1}
    x = filter(u -> !isa(u, Missing) && u != "", x)
    convert(Array{String, 1}, x)
end

#-------------------------------------------------------------------------------
# trim
trim(x::String)::String = string(strip(x))
trim(x::Array{String,1})::Array{String,1} = trim.(x)

#-------------------------------------------------------------------------------
# timestamp_format
timestamp_format(x::Missing, y::Regex)::Bool = false
timestamp_format(x::String, y::Regex)::Bool = occursin(y, trim(x))
function timestamp_format(x::Array, y::Regex)::Bool
    x = no_empty_char(x)
    if isa(x, Nothing)
        return false
    end
    length(x) <= 0 ? false : sum(occursin.(Ref(y), trim(x))) == length(x)
end

#-------------------------------------------------------------------------------
# to_timestamp
to_timestamp(x::Missing, y::String) = missing
function to_timestamp(x::String, y::String)
    x = replace(x, r"Z{0,1}$" => "")
    x = Dates.DateTime(x, y)
    TimeZones.ZonedDateTime(x, DBnomics.timestamp_tz)
end

#-------------------------------------------------------------------------------
# date_format
date_format(x::Missing)::Bool = false
date_format(x::String)::Bool = occursin(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$", trim(x))
function date_format(x::Array)::Bool
    x = no_empty_char(x)
    if isa(x, Nothing)
        return false
    end
    if length(x) <= 0
        return false
    end
    sum(occursin.(Ref(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"), trim(x))) == length(x)
end

#-------------------------------------------------------------------------------
# to_date
to_date(x::Missing)::Missing = missing
to_date(x::String)::Dates.Date = Dates.Date(x, "y-m-d")

#-------------------------------------------------------------------------------
# filter_true
filter_true(x::Dict{Symbol, Bool})::Dict{Symbol, Bool} = filter(u -> (last(u) == true), x)
filter_true(x::Dict{String, Bool})::Dict{String, Bool} = filter(u -> (last(u) == true), x)
# filter_true(x::Dict) = filter(d -> (last(d) == true), x)

#-------------------------------------------------------------------------------
# elt_to_array
elt_to_array(x::Dict) = Dict(k => isa(v, Array) ? v : [v] for (k, v) in x)
elt_to_array(x::NamedTuple) = map(u -> isa(u, Array) ? u : [u], x)

# elt_to_array!
function elt_to_array!(x::Dict)::Nothing
    for k in keys(x)
        if !isa(x[k], Array)
            push!(x, k => [x[k]])
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# to_json_if_dict_namedtuple
to_json_if_dict_namedtuple(x::Dict) = JSON.json(elt_to_array!(x))
to_json_if_dict_namedtuple(x::NamedTuple) = JSON.json(elt_to_array(x))
to_json_if_dict_namedtuple(x::String) = x

#-------------------------------------------------------------------------------
# has_missing
has_missing(x::Missing)::Bool = true
has_missing(x::Array)::Bool = collect(skipmissing(x)) != x
has_missing(x::Any)::Bool = isa(x, Missing)

#-------------------------------------------------------------------------------
# has_numeric_NA
function has_numeric_NA(x)::Bool
    ref_num::Base.RefValue{Regex} = Ref(r"^[0-9]*[[:blank:]]*[0-9]+\.*[0-9]*$")
    ref_NA::Base.RefValue{Regex} = Ref(r"^NA$")
    try
        tmp_x = trim(string.(x))
        (sum(occursin.(ref_num, tmp_x)) > 0) && (sum(occursin.(ref_NA, tmp_x)) > 0)
    catch
        false
    end
end

#-------------------------------------------------------------------------------
# filter_type
function filter_type(x::Tuple)::String
    test = try
        res = "ko"
        n = length(x)
        y = map(filter_ok, x)
        y = sum(y)
        y == n ? "tuple" : res
    catch
        "ko"
    end

    test
end

function filter_type(x::Dict)::String
    # When Dict
    test = try
        res = filter_ok(x)
        res ? "nottuple" : "ko"
    catch
        "ko"
    end
  
    test
end

#-------------------------------------------------------------------------------
# filter_ok
function filter_ok(x::Dict)::Bool
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
# ckeys
ckeys(x::Dict)::Array = collect(keys(x))

#-------------------------------------------------------------------------------
# ckeys_string
ckeys_string(x::Dict)::Array{String, 1} = string.(collect(keys(x)))

#-------------------------------------------------------------------------------
# cvalues
cvalues(x::Dict)::Array = collect(values(x))

#-------------------------------------------------------------------------------
# Dict_to_NamedTuple
Dict_to_NamedTuple(x::Dict) = NamedTuple{Tuple(Symbol.(keys(x)))}(values(x))

#-------------------------------------------------------------------------------
# readurl
function readurl(x::String)::String
    content = readlines(download(x))
    isa(content, Array) ? content[1] : content
end

#-------------------------------------------------------------------------------
# concatenate_dict
concatenate_dict(x::Dict) = concatenate_dict([x])
function concatenate_dict(x::Array)
    all_keys = ckeys_string.(x)
    all_keys = unique(all_keys)
    all_keys = vcat(all_keys...)
    all_keys = unique(all_keys)
    
    x = map(x) do u
        u = harmonize_dict(u)
        len_dict = length_element(u)
        if isa(len_dict, Nothing)
            irep = 1
        else
            irep = len_dict
        end

        nm_x = ckeys(u)
        add_x = setdiff(all_keys, string.(nm_x))
        if length(add_x) > 0
            for new_col in add_x
                push!(u, Symbol(new_col) => repeat([missing], irep))
            end
        end
        DataStructures.sort!(DataStructures.OrderedDict(u))
        u
    end

    tmp_x = Dict()
    if length(x) > 0
        for id in 1:length(x)
            merge!(vcat, tmp_x, x[id])
        end
    end

    Dict{Symbol, Array{T, 1} where T}(tmp_x)
end

#-------------------------------------------------------------------------------
# transform_date_timestamp!
function transform_date_timestamp!(kv::Dict, y::Union{Nothing, Symbol} = nothing)::Nothing
    from_timestamp_format::Array{Regex,1} = [
      r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.{0,1}[0-9]*Z{0,1}$",
      r"^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:blank:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$"
    ]

    to_timestamp_format::Array{String,1} = ["y-m-dTH:M:S.s", "y-m-d H:M:S"]

    if isa(y, Nothing)
        y = keys(kv)
    end

    for k in y
        if isa(kv[k], Array{String, 1}) || isa(kv[k], Array{Union{Missing, String}, 1})
            x = unique(skipmissing(kv[k]))
            if date_format(x)
                push!(kv, k => to_date.(kv[k]))
            end
            for i in 1:length(from_timestamp_format)
                if timestamp_format(x, from_timestamp_format[i])
                    push!(kv, k => to_timestamp.(kv[k], Ref(to_timestamp_format[i])))
                end
            end
        end
    end
    
    nothing
end

#-------------------------------------------------------------------------------
# unlist
function unlist(arr)
    rst = Any[]
    grep(v::Array) = for x in v
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
# clean_data
function clean_data(
    x::Union{Array{Any, 1}, Array{Dict{String, Any}, 1}},
    copy_values::Bool = false
)
    x = to_dict.(x)
    x = concatenate_dict(x)
    if !haskey(x, :value)
        return nothing
    end
    if copy_values
        original_values = x[:value]
    end
    change_type!(x)
    transform_date_timestamp!(x)
    if copy_values
        original_value_to_string!(x, original_values)
    end
    x
end

#-------------------------------------------------------------------------------
# rename_dict!
function rename_dict!(x::Dict, old_key::Symbol, new_key::Symbol)::Nothing
    x[new_key] = pop!(x, old_key)
    nothing
end

#-------------------------------------------------------------------------------
# original_value_to_string!
function original_value_to_string!(x::Dict, y::Array)::Nothing
    push!(x, :original_value => [isa(u, Missing) ? missing : string(u) for u in y])
    nothing
end

#-------------------------------------------------------------------------------
# NamedTuple_to_Dict
NamedTuple_to_Dict(x::NamedTuple)::Dict = Dict(pairs(x))

#-------------------------------------------------------------------------------
# reduce_to_one!
function reduce_to_one!(x::Dict)::Nothing
    for k in keys(x)
        if length(unique(x[k])) > 1
            delete!(x, k)
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# get_value
get_value(x::Dict)::Array = sort(vcat([v for (k, v) in x]...))

#-------------------------------------------------------------------------------
# remove_provider
remove_provider!(x::Nothing)::Nothing = nothing
function remove_provider!(x::Array)::Nothing
    map(x) do u
        u[1] = replace(u[1], r".*/" => "")
        u
    end
    nothing
end

#-------------------------------------------------------------------------------
# change_type!
change_type!(x::Nothing)::Nothing = nothing
function change_type!(
    x::Dict, y::Union{Nothing, Symbol} = nothing, except::Array = []
)::Nothing
    if isa(y, Nothing)
        y = keys(x)
    end
    for k in y
        if !(k in except)
            push!(x, k => simplify_type(x[k]))
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# simplify_type
function simplify_type(x)
    if has_numeric_NA(x)
        x = convert(Array{Union{Missing, Any}, 1}, x)
        x = map(u -> u == "NA" ? missing : u, x)
        return simplify_type(x)
    end

    hm = has_missing(x)

    if isa(x, Array{Any, 1}) || isa(x, Array{String, 1})
        result = try
            hm ? convert(Array{Union{Missing, Int64}, 1}, x) : convert(Array{Int64, 1}, x)
        catch
            try
                hm ? convert(Array{Union{Missing, Float64}, 1}, x) : convert(Array{Float64, 1}, x)
            catch
                try
                    hm ? convert(Array{Union{Missing, String}, 1}, x) : convert(Array{String, 1}, x)
                catch
                    x
                end
            end
        end
    else
        result = hm ? x : collect(skipmissing(x))
    end

    result
end

#-------------------------------------------------------------------------------
# dict_types
function dict_types(x::Dict)::Nothing
    [println(k, " : ", typeof(v)) for (k, v) in x]
    nothing
end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# get_data
function get_data(
    x::String, userl::Bool = false, frun::Int64 = 0,
    headers::Union{Nothing, Array{Pair{String,String},1}} = nothing,
    body::Union{Nothing, String} = nothing;
    curl_conf...
)
    if (frun > 0)
        sys_sleep::Int64 = DBnomics.sleep_run
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
                if !isa(headers, Nothing) && !isa(body, Nothing)
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

        if frun < try_run
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
)::Nothing
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
# get_geo_colname
function get_geo_colname(x::Dict)
    # First try with multiple datasets
    # OK !
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
        # OK !
        try
            subdict = x["dataset"]
            output = []
            keys_ = ckeys(subdict)
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
    # OK !
    nm = "datasets" in keys(x) ? "datasets" : "dataset"

    if nm == "datasets"
        result = map(colname) do u
            k = replace(u[1], r".*/" => "")

            z = retrieve(x["datasets"][u[1]], Regex("^" * u[2] * "\$"))
            try
                z = Dict(
                    Symbol(k * "|" * u[2]) => string.(ckeys(z[1])),
                    Symbol(k * "|" * u[3]) => string.(cvalues(z[1]))
                )
            catch
                z = nothing
            end
            z
        end
        output = Dict()
        for res in result
            push!(output, ckeys(res)[1] => res[ckeys(res)[1]])
            push!(output, ckeys(res)[2] => res[ckeys(res)[2]])
        end
        output
    elseif nm == "dataset"
        # Second try with only one dataset
        # OK !
        result = map(colname) do u
            subdict = x["dataset"]
            k = replace(u[1], r".*/" => "")

            keys_ = ckeys(subdict)
            k_ = keys_[
                occursin.(Ref(r"^dimensions_value[s]*_label[s]*$"), keys_)
            ]
        
            z = subdict[k_[1]][u[2]]
            try
                z = Dict(
                    Symbol(u[1] * "|" * u[2]) => string.(ckeys(z)),
                    Symbol(u[1] * "|" * u[3]) => string.(cvalues(z))
                )
            catch
                z = nothing
            end
            z
        end
        output = Dict()
        for res in result
            push!(output, ckeys(res)[1] => res[ckeys(res)[1]])
            push!(output, ckeys(res)[2] => res[ckeys(res)[2]])
        end
        output
    else
        nothing
    end
end

#-------------------------------------------------------------------------------
# to_dict
function to_dict(x::Dict)
    # For 'observations_attributes'
    reflen::Int64 = 0
    if haskey(x, "value")
        reflen = length(x["value"])
    elseif haskey(x, "name")
        reflen = length(x["name"])
    end

    col_array = Dict(string(k) => isa(v, Array) for (k, v) in x)
    col_array = filter_true(col_array)
    col_array = ckeys(col_array)

    if length(col_array) > 0
        col_array = Dict(string(u) => unlist(x[u]) for u in col_array)
        lens = Dict(string(k) => length(v) for (k, v) in col_array)
        
        for (k, v) in lens
            if v == reflen
                break
            end
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

    # Dicts in values
    hasdict = Dict(string(k) => isa(v, Dict) for (k, v) in x)
    hasdict = [k for (k, v) in hasdict if v == true]

    if length(hasdict) <= 0
        return x
    end

    intern_dicts = map(hasdict) do y
        id = x[y]
        delete!(x, y)
        id
    end

    x = vcat(x, intern_dicts)

    reduce(merge, x)
end

#-------------------------------------------------------------------------------
function select_dict(x::Dict, k::Symbol, v::Union{String, Array{String, 1}})
    if isa(v, String)
        v = [v]
    end
    index = map(v) do u
        findall(isequal(u), x[k])
    end
    index = vcat(index...)
    Dict(k => v[index] for (k, v) in x)
end

#-------------------------------------------------------------------------------
function delete_dict!(x::Dict, k::Symbol)::Nothing
    delete!(x, k)
    nothing
end

function delete_dict!(x::Dict, k::Array{Symbol, 1})::Nothing
    for ik in k
        delete_dict!(x, ik)
    end
    nothing
end

function delete_dict!(
    x::Dict, k::Union{String, Array{String, 1}, Regex},
    expr::Bool = false
)::Nothing
    colnames = string.(keys(x))
    if expr
        cols = colnames[occursin.(Ref(k), colnames)]
    else
        k = isa(k, String) ? [k] : k
        cols = intersect(k, colnames)
    end
    if length(cols) > 0
        delete_dict!(x, Symbol.(k))
    end
    nothing
end

#-------------------------------------------------------------------------------
# additional_info
function additional_info(x::Dict)
    # Additional informations to translate geo, freq, ...
    if !DBnomics.translate_codes
        cols = maps = nothing
    else
        cols = get_geo_colname(x)
        maps = get_geo_names(x, cols)

        if !isa(cols, Nothing) && !isa(maps, Nothing)
            remove_provider!(cols)
            cols = [
                [Symbol(agc[1] * "|" * agc[2]), Symbol(agc[1] * "|" * agc[3])]
                for agc in cols
            ]
            # Check coherence
            if isa(cols, Nothing) || isa(maps, Nothing)
                cols = maps = nothing
            else
                keep = deepcopy(cols)
                if length(cols) != length(maps) / 2
                    cols = maps = nothing
                else
                    for iaddg in 1:length(cols)
                        if isa(cols[iaddg][1], Nothing) |
                        isa(cols[iaddg][2], Nothing)
                            deleteat!(keep, iaddg)
                            try
                                pop!(maps, cols[iaddg][1])
                            catch
                            end
                            try
                                pop!(maps, cols[iaddg][2])
                            catch
                            end
                        else
                            if isa(maps[cols[iaddg][1]], Nothing) |
                            isa(maps[cols[iaddg][2]], Nothing)
                                deleteat!(keep, iaddg)
                                pop!(maps, cols[iaddg][1])
                                pop!(maps, cols[iaddg][2])
                            end
                        end
                    end
                end
                if length(keep) == 0
                    cols = maps = nothing
                else
                    cols = keep
                end
            end
        end
    end
    (cols, maps)
end

#-------------------------------------------------------------------------------
# additional_info_add
function additional_info_add(x::Dict, cols, maps)
    if !isa(cols, Nothing) && !isa(maps, Nothing)
        for i = 1:length(cols)
            dc = cols[i][1]
            dc = replace(string(dc), r"\|.*" => "")

            addcol = cols[i][2]
            addcol = Symbol(replace(string(addcol), dc * "|" => ""))
            
            suffix = ""
            if Symbol(addcol) in ckeys(x)
                suffix = "_add"
                newcol = Symbol(string(addcol) * suffix)

                push!(
                    maps,
                    Symbol(dc * "|" * string(newcol)) => maps[cols[i][2]]
                )
                delete_dict!(maps, cols[i][2])
                cols[i][2] = Symbol(dc * "|" * string(newcol))
            end

            ref_col = replace(string(cols[i][1]), dc * "|" => "")
            new_col = replace(string(cols[i][2]), dc * "|" => "")
            n = length(x[Symbol(ref_col)])
            push!(x, Symbol(new_col) => Array{Any}(missing, n))
            for j in 1:n
                if x[:dataset_code][j] == dc
                    if isa(x[Symbol(ref_col)][j], Missing)
                        x[Symbol(new_col)][j] = missing
                    else
                        i_ = findall(
                            isequal(x[Symbol(ref_col)][j]),
                            maps[cols[i][1]]
                        )[1]
                        x[Symbol(new_col)][j] = maps[cols[i][2]][i_]
                    end
                end
            end

            if suffix != ""
                old_col = replace(new_col, "_add" => "")
                for j in 1:n
                    if x[:dataset_code][j] == dc
                        if isa(x[Symbol(old_col)][j], Missing)
                            x[Symbol(old_col)][j] = x[Symbol(new_col)][j]
                        end
                    end
                end
                pop!(x, Symbol(new_col))
            end
        end
    end

    x
end

#-------------------------------------------------------------------------------
# extract_children
extract_children(x::Array) = extract_children.(x)
function extract_children(x::Dict)
    if "children" in keys(x)
        extract_children.(x["children"])
    else
        x
    end
end

#-------------------------------------------------------------------------------
# extract_dict
extract_dict(x::Array) = vcat(extract_dict.(x)...)
extract_dict(x::Dict) = x

#-------------------------------------------------------------------------------
# stack_dict
function stack_dict(x::Array)
    tmp_x = typeof(x[1])()
    for id in 1:length(x)
        merge!(vcat, tmp_x, x[id])
    end
    tmp_x
end

#-------------------------------------------------------------------------------
# showkeys
function showkeys(x, level::Int = 0; showall::Bool = false)
    if isa(x, Dict)
        ks = sort(string.(keys(x)))
        if !showall
            if length(ks) > 10
                ks = vcat([ks[1:5], "...", ks[end - 4:end]]...)
            end
        end
        for k in ks
            if haskey(x, k)
                len = isa(x[k], Dict) ? " (" * string(length(x[k])) * ")" : ""
            elseif haskey(x, Symbol(k))
                len = isa(x[Symbol(k)], Dict) ? " (" * string(length(x[Symbol(k)])) * ")" : ""
            else
                len = ""
            end
            println("\t" ^ level, k, len)
            if haskey(x, k)
                showkeys(x[k], level + 1; showall = showall)
            elseif haskey(x, Symbol(k))
                showkeys(x[Symbol(k)], level + 1; showall = showall)
            end
        end
    end
end