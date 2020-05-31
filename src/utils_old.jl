#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# repeat_df
# function repeat_df(x::Array{DataFrames.DataFrame, 1}, n::Int64) 
#     repeat.(x, Ref(n))
# end

#-------------------------------------------------------------------------------
# concatenate_data
# function concatenate_data(
#     x::Union{DataFrames.DataFrame, Array},
#     y::Union{DataFrames.DataFrame, Nothing} = nothing
# )
#     if isa(y, Nothing)
#         return reduce(concatenate_data, x)
#     end

#     nm_x, nm_y = names.([x, y])

#     allowmissing!.([x, y])

#     add_x = setdiff(nm_y, nm_x)
#     if length(add_x) > 0
#         df_complete_missing!(x, add_x)
#     end
    
#     add_y = setdiff(nm_x, nm_y)
#     if length(add_y) > 0
#         df_complete_missing!(y, add_y)
#     end
    
#     [x; y[selectop, names(x)]]
# end

#-------------------------------------------------------------------------------
# # Dict_to_JuliaDB
# function Dict_to_JuliaDB(x::Dict)
#     x = key_to_symbol(x)
#     x = value_to_array(x)
#     x = Dict_to_NamedTuple(x)
#     table(x)
# end

#-------------------------------------------------------------------------------
# # NamedTuple_to_JuliaDB
# NamedTuple_to_JuliaDB(x::NamedTuple) = Dict_to_JuliaDB(NamedTuple_to_Dict(x))

#-------------------------------------------------------------------------------
# # JuliaDB_to_Dict
# function JuliaDB_to_Dict(x::IndexedTable)
#     x = JuliaDB_to_NamedTuple(x)
#     NamedTuple_to_Dict(x)
# end

#-------------------------------------------------------------------------------
# # JuliaDB_to_NamedTuple
# JuliaDB_to_NamedTuple(x::IndexedTable) = columns(x)

#-------------------------------------------------------------------------------
# original_value_to_string
# function original_value_to_string!(x::DataFrames.DataFrame, y)
#     y = if isa(y, Array{Any,1})
#         try string.(y) catch; y end
#     elseif isa(y, Any)
#         try string(y) catch; y end
#     else
#         y
#     end
#     x[selectop, :original_value] = y
#     nothing
# end

#-------------------------------------------------------------------------------
# reduce_to_one!
# function reduce_to_one!(DT::DataFrames.DataFrame)
#     x = Dict{String, Int64}()

#     for col in names(DT)
#         push!(x, string(col) => length(unique(DT[selectop, col])))
#     end

#     x = filter(u -> u[2] > 1, x)
#     if length(x) > 0
#         x = Symbol.(keys(x))
#         df_delete_col!(DT, x)
#     end
  
#     nothing
# end

#-------------------------------------------------------------------------------
# change_type!
# function change_type!(DT::DataFrames.DataFrame)::Nothing
#     for col in names(DT)
#         DT[selectop, col] = simplify_type(DT[selectop, col])
#     end
#     nothing
# end

#-------------------------------------------------------------------------------
# to_dataframe
# function to_dataframe(x::Dict)
#     # For 'observations_attributes'
#     if haskey(x, "value")
#         reflen = length(x["value"])
#     elseif haskey(x, "name")
#         reflen = length(x["name"])
#     end

#     col_array = Dict(string(k) => isa(v, Array) for (k, v) in x)
#     col_array = filter_true(col_array)
#     col_array = collect(keys(col_array))

#     if length(col_array) > 0
#         col_array = Dict(zip(col_array, map(u -> unlist(x[u]), col_array)))
#         lens = Dict(string(k) => length(v) for (k, v) in col_array)
        
#         for (k, v) in lens
#             if v == 1
#                 delete!(x, k)
#                 x[k] = col_array[k][1] * ","
#             elseif v == 2
#                 delete!(x, k)
#                 x[k] = col_array[k][1] * "," * col_array[k][2]
#             elseif v == reflen + 1
#                 delete!(x, k)
#                 x[k] = col_array[k][1] .* "," .* col_array[k][2:end]
#             elseif v != reflen
#                 delete!(x, k)
#                 x[k] = reduce((u, w) -> u * "," * w, unique(col_array[k]))
#             end
#         end
#     end

#     # Dict
#     hasdict = Dict(string(k) => isa(v, Dict) for (k, v) in x)
#     hasdict = [k for (k, v) in hasdict if v == true]

#     if length(hasdict) <= 0
#         return DataFrame(x)
#     end

#     intern_dicts = map(hasdict) do y
#         intern_dict = DataFrame(x[y])
#         delete!(x, y)
#         intern_dict
#     end

#     x = DataFrame(x)
    
#     intern_dicts = repeat_df(intern_dicts, nrow(x))
#     intern_dicts = reduce(hcat, intern_dicts)

#     [x intern_dicts]
# end

#-------------------------------------------------------------------------------
# concatenate_dict
# function concatenate_dict(
#     x::Union{Dict, Array},
#     y::Union{Dict, Nothing} = nothing
# )
#     if isa(y, Nothing)
#         if isa(x, Dict)
#             x = value_to_array(x)
#             x = key_to_symbol(x)
#             return convert(Dict{Symbol,Array{T,1} where T}, x)
#         else
#             return reduce(concatenate_dict, x)
#         end
#     end

#     x = value_to_array(x)
#     x = key_to_symbol(x)
#     x = convert(Dict{Symbol,Array{T,1} where T}, x)
    
#     y = value_to_array(y)
#     y = key_to_symbol(y)
#     y = convert(Dict{Symbol,Array{T,1} where T}, y)
    
#     nm_x, nm_y = keys.([x, y])

#     add_x = setdiff(nm_y, nm_x)
#     if length(add_x) > 0
#         for new_col in add_x
#             push!(x, new_col => [missing])
#         end
#     end
    
#     add_y = setdiff(nm_x, nm_y)
#     if length(add_y) > 0
#         for new_col in add_y
#             push!(y, new_col => [missing])
#         end
#     end
    
#     for k in keys(x)
#         push!(x, k => vcat(x[k], y[k]))
#     end

#     y = nothing

#     x
# end

#-------------------------------------------------------------------------------
# value_to_array
# function value_to_array(x::Dict)::Dict
#     x = Dict(k => isa(v, Array) ? v : [v] for (k, v) in x)

#     len = Dict(k => length(v) for (k, v) in x)
#     len = cvalues(len)
#     len = maximum(len)

#     Dict(k => length(v) != len ? repeat(v, len) : v for (k, v) in x)
# end

#-------------------------------------------------------------------------------
# transform_date_timestamp!
# function transform_date_timestamp!(DT::DataFrames.DataFrame)
#     from_timestamp_format = [
#       r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z{0,1}$",
#       r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+Z{0,1}$",
#       r"^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:blank:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$"
#     ]

#     to_timestamp_format = [
#       "y-m-dTH:M:S",
#       "y-m-dTH:M:S.s",
#       "y-m-d H:M:S"
#     ]

#     for col in names(DT)
#         x = DT[selectop, col]
#         if isa(x, Array{String, 1}) || isa(x, Array{Union{Missing, String}, 1})
#             if date_format(x)
#                 DT[selectop, col] = to_date.(x)
#             end
#             for i in 1:length(from_timestamp_format)
#                 if timestamp_format(x, from_timestamp_format[i])
#                     DT[selectop, col] = to_timestamp.(x, Ref(to_timestamp_format[i]))
#                 end
#             end
#         end
#     end
#     nothing
# end

#-------------------------------------------------------------------------------
# remove_columns
# function remove_columns!(
#     DT::DataFrames.DataFrame, x::Union{String, Array{String, 1}, Regex},
#     expr::Bool = false
# )
#     colnames = string.(names(DT))
#     if expr
#         cols = colnames[occursin.(Ref(x), colnames)]
#     else
#         if isa(x, String)
#             x = [x]
#         end
#         cols = intersect(x, colnames)
#     end
#     if length(cols) > 0
#         df_delete_col!(DT, Symbol.(x))
#     end
#     nothing
# end

#-------------------------------------------------------------------------------
    # # rdb_providers columns
    # global column_rdb_providers = Dict(
    #     :int64 => [],
    #     :float64 => [],
    #     :string => [
    #         :terms_of_use, :json_data_commit_ref, :code, :name, :website,
    #         :region, :slug
    #     ],
    #     :date => [],
    #     :timestamp => [:indexed_at, :created_at, :converted_at]
    # )
    # # rdb_last_updates columns
    # global column_rdb_last_updates = Dict(
    #     :int64 => [:nb_series],
    #     :float64 => [],
    #     :string => [
    #         :json_data_commit_ref, :code, :name, :provider_name, :provider_code,
    #         :description
    #     ],
    #     :date => [],
    #     :timestamp => [:converted_at, :created_at, :indexed_at, :updated_at]
    # )
    # # rdb columns
    # global column_rdb = Dict(
    #     :int64 => [],
    #     :float64 => [:value],
    #     :string => [
    #         :dataset_name, :series_code, :dataset_code, :provider_code,
    #         :series_name, :observations_attributes, :REF_AREA, :period,
    #         :INDICATOR, :FREQ, Symbol("@frequency"), :original_value
    #     ],
    #     :date => [:period_start_day],
    #     :timestamp => [:indexed_at]
    # )

# change_types!
# function change_types!(x::Dict, y::String)::Nothing
#     from_timestamp_format::Array{Regex,1} = [
#       # r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z{0,1}$",
#       r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.{0,1}[0-9]*Z{0,1}$",
#       r"^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:blank:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$"
#     ]

#     to_timestamp_format::Array{String,1} = [
#       # "y-m-dTH:M:S",
#       "y-m-dTH:M:S.s",
#       "y-m-d H:M:S"
#     ]

#     cols = nothing
#     if y == "rdb_providers"
#         cols = DBnomics.column_rdb_providers
#     elseif y == "rdb_last_updates"
#         cols = DBnomics.column_rdb_last_updates
#     elseif y == "rdb"
#         cols = DBnomics.column_rdb
#     end
#     if isa(cols, Nothing)
#         return nothing
#     end

#     if length(cols[:int64]) > 0
#         for k in cols[:int64]
#             if k in keys(x)
#                 if has_numeric_NA(x[k])
#                     tmp_x = convert(Array{Union{Missing, Any}, 1}, x[k])
#                     tmp_x = map(u -> u == "NA" ? missing : u, tmp_x)
#                     push!(x, k => tmp_x)
#                 end

#                 if has_missing(x[k])
#                     push!(x, k => convert(Array{Union{Missing, Int64}, 1}, x[k]))
#                 else
#                     push!(x, k => convert(Array{Int64, 1}, x[k]))
#                 end
#             end
#         end
#     end

#     if length(cols[:float64]) > 0
#         for k in cols[:float64]
#             if k in keys(x)
#                 if has_numeric_NA(x[k])
#                     tmp_x = convert(Array{Union{Missing, Any}, 1}, x[k])
#                     tmp_x = map(u -> u == "NA" ? missing : u, tmp_x)
#                     push!(x, k => tmp_x)
#                 end

#                 if has_missing(x[k])
#                     push!(x, k => convert(Array{Union{Missing, Float64}, 1}, x[k]))
#                 else
#                     push!(x, k => convert(Array{Float64, 1}, x[k]))
#                 end
#             end
#         end
#     end

#     if length(cols[:string]) > 0
#         for k in cols[:string]
#             if k in keys(x)
#                 if has_missing(x[k])
#                     push!(x, k => convert(Array{Union{Missing, String}, 1}, x[k]))
#                 else
#                     push!(x, k => convert(Array{String, 1}, x[k]))
#                 end
#             end
#         end
#     end

#     if length(cols[:date]) > 0
#         for k in cols[:date]
#             if k in keys(x)
#                 push!(x, k => to_date.(x[k]))
#             end
#         end
#     end

#     if length(cols[:timestamp]) > 0
#         for k in cols[:timestamp]
#             if k in keys(x)
#                 z = unique(skipmissing(x[k]))
#                 for i in 1:length(from_timestamp_format)
#                     if timestamp_format(z, from_timestamp_format[i])
#                         push!(x, k => to_timestamp.(x[k], Ref(to_timestamp_format[i])))
#                     end
#                 end
#             end
#         end
#     end

#     nothing
# end

#-------------------------------------------------------------------------------