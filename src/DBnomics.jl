module DBnomics
    #---------------------------------------------------------------------------
    # If the version of Julia is lower than 0.7.0, the packages "Missings"
    # and "NamedTuples" are needed.
    version7 = VERSION < VersionNumber("0.7.0");

    if version7
        if !isdir(Pkg.dir("Missings")) | !isdir(Pkg.dir("NamedTuples"))
            println(
                "Package 'Missings' and 'NamedTuples' are required for Julia " *
                "versions lower than 0.7.0. You are using version " *
                string(VERSION) * "."
            )
            println("Install 'Missings' and/or 'NamedTuples' to continue.")
            pkgs = ["Missings", "NamedTuples"];
            check = map(u -> isdir(Pkg.dir(u)) ? "ok" : "please install", pkgs);
            display(Dict(zip(pkgs, check)))
            println(
                """Install with Pkg.add("...") to continue."""
            )
            error(
                """A required package is missing."""
            )
        end
    end

    #---------------------------------------------------------------------------
    # Load packages.
    using DataFrames
    if version7
        import Base.Dates
        using Missings
        using NamedTuples
    else
        import Dates
    end
    import HTTP
    import JSON
    import TimeZones

    #---------------------------------------------------------------------------
    # Nothing
    if version7
        # Nothing doesn't exist before v0.7.0
        Nothing = Void
    end

    # occursin
    if version7
        # contains has been renamed to occursin
        function occursin(needle, haystack)
            contains(haystack, needle)
        end
    end

    # filter
    if version7
        function filter_true(x::Dict) 
            filter((k, v) -> v == true, x)
        end
    else
        function filter_true(x::Dict) 
            filter(d -> (last(d) == true), x)
        end
    end

    # repeat_df
    if version7
        function repeat_df(x::Array{DataFrames.DataFrame, 1}, n::Int64) 
            map(x) do internx
                reduce((u, v) -> vcat(u, v), repeat([internx], n))
            end
        end
    else
        function repeat_df(x::Array{DataFrames.DataFrame, 1}, n::Int64) 
            repeat.(x, Ref(n))
        end
    end

    # df_delete_col
    if version7
        function df_delete_col!(x::DataFrames.DataFrame, y)
            delete!(x, y)
        end
    else
        function df_delete_col!(x::DataFrames.DataFrame, y)
            deletecols!(x, y)
        end
    end

    #---------------------------------------------------------------------------
    # Global variables.
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
    global timestamp_tz = TimeZones.tz"GMT"
    # Number of tries of get_data
    global try_run = 2
    # Warning for ids in rdb
    global verbose_warning = true
    # Download metadata
    global metadata = false

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
        DBnomics.options("timestamp_tz", TimeZones.tz"GMT")
        DBnomics.options("try_run", 2)
        DBnomics.options("verbose_warning", true)
        DBnomics.options("metadata", false)

        nothing
    end

    #---------------------------------------------------------------------------
    # Functions
    include("utils.jl")
    include("rdb_by_api_link.jl")
    include("rdb.jl")
    include("rdb_last_updates.jl")
    include("rdb_providers.jl")

    #---------------------------------------------------------------------------
    export rdb_by_api_link, rdb, rdb_last_updates, rdb_providers
end # module
