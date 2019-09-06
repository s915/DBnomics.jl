module DBnomics
    #---------------------------------------------------------------------------
    # Julia version greater or equal to 1.2.0
    version12 = (VERSION >= VersionNumber("0.7.0")) & (VERSION < VersionNumber("1.2.0"));
    # WARNING
    # For Julia v0.7, JSON version must be 0.20.0 because of Parsers
    if VERSION < VersionNumber("1.0.0")
        import Pkg
        Parsers_version = Pkg.installed()["Parsers"] <= VersionNumber("0.3.0")
        JSON_version = Pkg.installed()["JSON"] >= VersionNumber("0.21.0")
        if Parsers_version & JSON_version
            error(
                "The package version of JSON must be 0.20.0 because of the " *
                "version of Parsers." *
                "\n" *
                """Please run "add JSON@0.20.0" in the package manager."""
            )
        end
    end

    #---------------------------------------------------------------------------
    # Load packages.
    using DataFrames
    import Dates
    import HTTP
    import JSON
    import TimeZones

    #---------------------------------------------------------------------------
    # DataFrames version
    df_test = DataFrame(A = 1, B = rand(1))
    DataFrames019 = try
        df_test[!, :A]
        false
    catch
        true
    end

    # df_delete_col
    if DataFrames019
        function df_delete_col!(x::DataFrames.DataFrame, y)
            deletecols!(x, y)
        end
    else
        function df_delete_col!(x::DataFrames.DataFrame, y)
            select!(x, Not(y))
        end
    end

    #---------------------------------------------------------------------------
    # Global variables.
    # Julia version lower than 1.2.0
    global version12 = version12
    # DataFrames version lower than 0.19
    global DataFrames019 = DataFrames019
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
    global metadata = true
    # Translate codes like ISO, geo, ...
    global translate_codes = true
    # Apply some filters to the series
    global filters = nothing
    # API editor url
    global editor_base_url = "https://editor.nomics.world"
    # API editor version
    global editor_version = 1

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
        DBnomics.options("metadata", true)
        DBnomics.options("translate_codes", true)
        DBnomics.options("filters", nothing)
        DBnomics.options("editor_version", 1)
        DBnomics.options("editor_base_url", "https://editor.nomics.world")

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
