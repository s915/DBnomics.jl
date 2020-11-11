# selectop
function selectop()
    df_test = DataFrames.DataFrame(A = 1, B = rand(1))
    try
        df_test[!, :A]
        (!)
    catch
        (:)
    end
end

#-------------------------------------------------------------------------------
# df_delete_col
function df_delete_col!(x::DataFrames.DataFrame, y)::Nothing
    if selectop() == (!)
        DataFrames.select!(x, Not(y))
    else
        DataFrames.deletecols!(x, y)
    end
    nothing
end

#-------------------------------------------------------------------------------
# printDT
function printDT(x::DataFrames.DataFrame, n::Union{Nothing, Int64} = nothing)
    if nrow(x) <= 10
        if isa(n, Nothing)
            x[selectop(), :_row_] = 1:nrow(x)
        else
            x[selectop(), :_row_] = vcat(1:5, (n - 4):n)
        end

        x = x[selectop(), [ncol(x); 1:(ncol(x) - 1)]]

        show(x, allcols = true)

        df_delete_col!(x, :_row_)
        nothing
    else
        y = [x[1:5,:]; x[(end - 4):end,:]]
        printDT(y, nrow(x))
    end
end

#-------------------------------------------------------------------------------
# df_new_col!
function df_new_col!(x::DataFrames.DataFrame, col::Symbol, y)::Nothing
    if selectop() == (!)
        x[!, col] .= y
    else
        x[:, col] = y
    end
    nothing
end

#-------------------------------------------------------------------------------
# df_return
function df_return(x::Dict)
    if DBnomics.returndf
        DF = DataFrames.DataFrame(x)
        DataFrames.select!(
            DF,
            DataFrames.sort(DataFrames.names(DF), by = lowercase)
        )
        DF
    else
        x
    end
end

#-------------------------------------------------------------------------------
# df_complete_missing!
function df_complete_missing!(
    x::DataFrames.DataFrame, add::Union{Symbol, Array{Symbol, 1}}
)::Nothing
    if selectop() == (!)
        for iadd in add
            x[!, iadd] .= Ref(missing)
        end
    else
        x[:, add] = missing
    end
    nothing
end

#-------------------------------------------------------------------------------
# df_empty_dict
function df_empty_dict()
    if DBnomics.returndf
        Dict{Symbol, DataFrames.DataFrame}()
    else
        Dict{Symbol, Any}()
    end
end

#-------------------------------------------------------------------------------
# extract_code
function extract_code(x::Dict)
    if isa(x[ckeys(x)[1]], Dict{Symbol, Array{String, 1}}) ||
    isa(x[ckeys(x)[1]], Dict{Symbol, Array{T, 1} where T})
        for k in keys(x)
            push!(x, k => x[k][:code])
        end
        x
    else
        y = Dict{Symbol, Array{String, 1}}()
        for k in keys(x)
            push!(y, k => x[k][selectop(), :code])
            pop!(x, k)
        end
        y
    end
end
