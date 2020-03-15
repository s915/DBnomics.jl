module DBnomics
    # Visit <https://db.nomics.world>
    println("Visit <https://db.nomics.world>.")

    #---------------------------------------------------------------------------
    # Julia version smaller than 1.2.0
    version12 = (VERSION >= VersionNumber("0.7.0")) & (VERSION < VersionNumber("1.2.0"));
    # WARNING
    # For Julia v0.7, JSON version must be 0.20.0 because of Parsers
    # If needed "add JSON@0.20.0" in the package manager.

    #---------------------------------------------------------------------------
    # Load packages.
    # using DataFrames
    using JuliaDB
    import Dates
    import HTTP
    import JSON
    import TimeZones

    #---------------------------------------------------------------------------
    # DataFrames version
    # df_test = DataFrame(A = 1, B = rand(1))
    # DataFrames019 = try (df_test[!, :A]; false) catch; true end

    # df_delete_col
    # if DataFrames019
    #     function df_delete_col!(x::DataFrames.DataFrame, y)
    #         deletecols!(x, y)
    #         nothing
    #     end
    # else
    #     function df_delete_col!(x::DataFrames.DataFrame, y)
    #         select!(x, Not(y))
    #         nothing
    #     end
    # end

    # selectop
    # selectop = DataFrames019 ? (:) : (!)

    # df_new_col
    # if DataFrames019
    #     function df_new_col!(x::DataFrames.DataFrame, col::Symbol, y)
    #         x[:, col] = y
    #         nothing
    #     end
    # else
    #     function df_new_col!(x::DataFrames.DataFrame, col::Symbol, y)
    #         x[!, col] .= y
    #         nothing
    #     end
    # end

    # df_complete_missing
    # if DataFrames019
    #     function df_complete_missing!(x::DataFrames.DataFrame, add::Union{Symbol, Array{Symbol, 1}})
    #         x[:, add] = missing
    #         nothing
    #     end
    # else
    #     function df_complete_missing!(x::DataFrames.DataFrame, add::Union{Symbol, Array{Symbol, 1}})
    #         for iadd in add
    #             x[!, iadd] .= Ref(missing)
    #         end
    #         nothing
    #     end
    # end

    # default_timezone
    default_timezone = try
        TimeZones.TimeZone("GMT")
    catch
        TimeZones.TimeZone("UTC")
    end

    #---------------------------------------------------------------------------
    # Global variables.
    # Julia version lower than 1.2.0
    global version12 = version12
    # DataFrames version lower than 0.19
    # global DataFrames019 = DataFrames019
    # API version
    global api_version = 22
    # API base url
    global api_base_url = "https://api.db.nomics.world"
    # Proxy configuration
    global curl_config = nothing
    # Check get response is ok
    global http_ok = 200
    # Use use_readlines and download instead of HTTP.get
    global use_readlines = false
    # Automatic transfer of unnamed argumnents in rdb
    global rdb_no_arg = true
    # Sleep time between tries
    global sleep_run = 1
    # Timezone
    global timestamp_tz = default_timezone
    # Number of tries of get_data
    global try_run = 2
    # Warning for ids in rdb
    global verbose_warning = true
    # Download metadata
    global metadata = true
    # Translate codes like ISO, geo, ...
    global translate_codes = true
    # Apply some filters to the series
    global filters = nothing
    # API editor url
    global editor_base_url = "https://editor.nomics.world"
    # API editor version
    global editor_version = 1
    # https connection
    global secure = true

    # Modify global variables
    function options(s::AbstractString, v::Any)
        s = Symbol(s)
        @eval (tmp = ($v))

        if String(s) == "api_version"
            if !isa(tmp, Int64)
                error("'api_version' must be an Int64.")
            end
        elseif String(s) == "api_base_url"
            if !isa(tmp, String)
                error("'api_base_url' must be a String.")
            end
        elseif String(s) == "curl_config"
            if !isa(tmp, Union{Nothing, Dict, NamedTuple})
                error("'curl_config' must be nothing, a Dict or a NamedTuple.")
            end
        elseif String(s) == "http_ok"
            if !isa(tmp, Int64)
                error("'http_ok' must be an Int64.")
            end
        elseif String(s) == "use_readlines"
            if !isa(tmp, Bool)
                error("'use_readlines' must be a Bool.")
            end
        elseif String(s) == "rdb_no_arg"
            if !isa(tmp, Bool)
                error("'rdb_no_arg' must be a Bool.")
            end
        elseif String(s) == "sleep_run"
            if !isa(tmp, Int64)
                error("'sleep_run' must be an Int64.")
            end
        elseif String(s) == "timestamp_tz"
            if !isa(
                tmp,
                Union{TimeZones.FixedTimeZone, TimeZones.VariableTimeZone}
            )
                error(
                    "'timestamp_tz' must be a TimeZones.FixedTimeZone or " *
                    " a TimeZones.VariableTimeZone."
                )
            end
        elseif String(s) == "try_run"
            if !isa(tmp, Int64)
                error("'try_run' must be an Int64.")
            end
        elseif String(s) == "verbose_warning"
            if !isa(tmp, Bool)
                error("'verbose_warning' must be a Bool.")
            end
        elseif String(s) == "metadata"
            if !isa(tmp, Bool)
                error("'metadata' must be a Bool.")
            end
        elseif String(s) == "translate_codes"
            if !isa(tmp, Bool)
                error("'translate_codes' must be a Bool.")
            end
        elseif String(s) == "editor_base_url"
            if !isa(tmp, String)
                error("'editor_base_url' must be a String.")
            end
        elseif String(s) == "editor_version"
            if !isa(tmp, Int64)
                error("'editor_version' must be an Int64.")
            end
        elseif String(s) == "secure"
            if !isa(tmp, Bool)
                error("'secure' must be a Bool.")
            end
        elseif String(s) == "filters"
            if !isa(tmp, Union{Nothing, Dict, Tuple})
               error("'filters' must be a Dict, a Tuple or Nothing.") 
            end
        else
            error("Invalid option name.")
        end

        @eval (($s) = ($v))

        nothing
    end

    function resetoptions()
        DBnomics.options("api_version", 22)
        DBnomics.options("api_base_url", "https://api.db.nomics.world")
        DBnomics.options("curl_config", nothing)
        DBnomics.options("http_ok", 200)
        DBnomics.options("use_readlines", false)
        DBnomics.options("rdb_no_arg", true)
        DBnomics.options("sleep_run", 1)
        try
            DBnomics.options("timestamp_tz", TimeZones.TimeZone("GMT"))
        catch
            DBnomics.options("timestamp_tz", TimeZones.TimeZone("UTC"))
        end
        DBnomics.options("try_run", 2)
        DBnomics.options("verbose_warning", true)
        DBnomics.options("metadata", true)
        DBnomics.options("translate_codes", true)
        DBnomics.options("filters", nothing)
        DBnomics.options("editor_version", 1)
        DBnomics.options("editor_base_url", "https://editor.nomics.world")
        DBnomics.options("secure", true)

        nothing
    end

    #---------------------------------------------------------------------------
    # Functions
    include("utils.jl")
    # include("C:/programming/Julia/packages/DBnomics/src/utils.jl")
    include("dot_rdb.jl")
    include("rdb_by_api_link.jl")
    include("rdb.jl")
    include("rdb_last_updates.jl")
    include("rdb_providers.jl")

    #---------------------------------------------------------------------------
    @deprecate rdb_by_api_link(api_link::String) rdb(api_link::Union{String, Nothing})
    
    #---------------------------------------------------------------------------
    export rdb_by_api_link, rdb, rdb_last_updates, rdb_providers
end # module
