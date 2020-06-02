# DBnomics.jl <img src="docs/src/assets/logo.png" align="right" width="360" />

## DBnomics Julia client

This package provides you access to DBnomics data series. DBnomics is an open-source project with the goal of aggregating the world's economic data in one location, free of charge to the public. DBnomics covers hundreds of millions of series from international and national institutions (Eurostat, World Bank, IMF, ...).

To use this package, you have to provide the codes of the provider, dataset and series you want. You can retrieve them directly on the <a href="https://db.nomics.world/" target="_blank">website</a>.

To install `DBnomics.jl`, go to the package manager with `]` :

```julia
add DBnomics
```
or install the github version with :

```julia
add https://github.com/s915/DBnomics.jl
```

All the functions, and their names, are derived from the R package <a href="https://github.com/dbnomics/rdbnomics" target="_blank"><b>rdbnomics</b></a> which I also maintain.

## Examples
Fetch time series by `ids` :
```julia
# Fetch one series from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");

# Fetch two series from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df2 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"]);

# Fetch two series from different datasets of different providers :
df3 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "IMF/BOP/A.FR.BCA_BP6_EUR"]);
```

In the event that you only use the argument `ids`, you can drop it and run :
```julia
df1 = rdb("AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
```

Fetch time series by `mask` :
```julia
# Fetch one series from dataset 'Balance of Payments' (BOP) of IMF :
df1 = rdb("IMF", "BOP", mask = "A.FR.BCA_BP6_EUR");

# Fetch two series from dataset 'Balance of Payments' (BOP) of IMF :
df2 = rdb("IMF", "BOP", mask = "A.FR+ES.BCA_BP6_EUR");

# Fetch all series along one dimension from dataset 'Balance of Payments' (BOP) of IMF :
df3 = rdb("IMF", "BOP", mask = "A..BCA_BP6_EUR");

# Fetch series along multiple dimensions from dataset 'Balance of Payments' (BOP) of IMF :
df4 = rdb("IMF", "BOP", mask = "A.FR.BCA_BP6_EUR+IA_BP6_EUR");
```

In the event that you only use the arguments `provider_code`, `dataset_code` and `mask`, you can drop the name `mask` and run :
```julia
df1 = rdb("IMF", "BOP", "A.FR.BCA_BP6_EUR");
```

Fetch time series by `dimensions` :
```julia
# Fetch one value of one dimension from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df1 = rdb("AMECO", "ZUTN", dimensions = Dict(:geo => "ea12"));
# or
df1 = rdb("AMECO", "ZUTN", dimensions = (geo = "ea12",));
# or
df1 = rdb("AMECO", "ZUTN", dimensions = """{"geo": ["ea12"]}""");

# Fetch two values of one dimension from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df2 = rdb("AMECO", "ZUTN", dimensions = Dict(:geo => ["ea12", "dnk"]));
# or
df2 = rdb("AMECO", "ZUTN", dimensions = (geo = ["ea12", "dnk"],));
# or
df2 = rdb("AMECO", "ZUTN", dimensions = """{"geo": ["ea12", "dnk"]}""");

# Fetch several values of several dimensions from dataset 'Doing business' (DB) of World Bank :
df3 = rdb("WB", "DB", dimensions = Dict(:country => ["DZ", "PE"], :indicator => ["ENF.CONT.COEN.COST.ZS", "IC.REG.COST.PC.FE.ZS"]));
# or
df3 = rdb("WB", "DB", dimensions = (country = ["DZ", "PE"], indicator = ["ENF.CONT.COEN.COST.ZS", "IC.REG.COST.PC.FE.ZS"]));
```

Fetch time series with a `query`:
```julia
# Fetch one series from dataset 'WEO by countries' (WEO) of IMF provider:
df1 = rdb("IMF", "WEO", query = "France current account balance percent");

# Fetch series from dataset 'WEO by countries' (WEO) of IMF provider:
df2 = rdb("IMF", "WEO", query = "current account balance percent");
```

Fetch one series from the dataset 'Doing Business' of WB provider with the link:
```julia
df1 = rdb(api_link = "https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22country%22%3A%5B%22FR%22%2C%22IT%22%2C%22ES%22%5D%7D&q=IC.REG.PROC.FE.NO&observations=1&format=json&align_periods=1&offset=0&facets=0");
```

In the event that you only use the argument `api_link`, you can drop the name and run:
```julia
df1 = rdb("https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22country%22%3A%5B%22FR%22%2C%22IT%22%2C%22ES%22%5D%7D&q=IC.REG.PROC.FE.NO&observations=1&format=json&align_periods=1&offset=0&facets=0");
```

Fetch the available datasets of a provider
```julia
# Example with the IMF datasets:
df_datasets = rdb_datasets("IMF");

# Example with the IMF and BDF datasets:
df_datasets = rdb_datasets(["IMF", "BDF"]);
```

In the event that you only request the datasets for one provider, if you define
`simplify = true`, then the result will be a `DataFrame` not a `Dict`.
```julia
df_datasets = rdb_datasets("IMF", simplify = true);
```

Fetch the possible dimensions of available datasets of a provider
```julia
# Example for the dataset WEO of the IMF:
df_dimensions = rdb_dimensions("IMF", "WEO");
```

In the event that you only request the dimensions for one dataset for one
provider, if you define `simplify = true`, then the result will be a `Dict` of
`DataFrame`s not a nested `Dict`.
```julia
df_dimensions = rdb_dimensions("IMF", "WEO", simplify = true);
```

Fetch the number of series of available datasets of a provider
```julia
# Example for the dataset WEOAGG of the IMF:
df_series = rdb_series("IMF", "WEOAGG");

# With dimensions
df_series = rdb_series("IMF", "WEO", dimensions = Dict(Symbol("weo-country") => "AGO");
df_series = rdb_series("IMF", "WEO", dimensions = Dict(Symbol("weo-subject") => "NGDP_RPCH"), simplify = true);

# With a query
df_series = rdb_series("IMF", "WEO", query = "ARE");
df_series = rdb_series("IMF", ["WEO", "WEOAGG"], query = "NGDP_RPCH");
```

:warning: We ask the user to use this function parsimoniously because there are a huge amount
of series per dataset. Please only fetch for one dataset if you need it or
visit the website [https://db.nomics.world](https://db.nomics.world).  

## Proxy configuration
When using the functions `rdb` or `rdb_...`, if you come across an error concerning your internet connection, you can get round this situation by :

1. configuring **curl** of the function `HTTP.get` or `HTTP.post` to use a specific and authorized proxy.

2. using the functions `readlines` and `download` if you have problem with `HTTP.get`.

### Configure **curl** to use a specific and authorized proxy
In **DBnomics.jl**, by default the function `HTTP.get` or `HTTP.post` are used to fetch the data. If a specific proxy must be used, it is possible to define it permanently with the package global variable `curl_config` or on the fly through the argument `curl_config`. In that way the object is passed to the keyword arguments of the function `HTTP.get` or `HTTP.post`.  
To see the available parameters, visit the website <a href="https://curl.haxx.se/libcurl/c/curl_easy_setopt.html" target="_blank">https://curl.haxx.se/libcurl/c/curl_easy_setopt.html</a>.  
Once they are chosen, you define the curl object as follows :
```julia
h = Dict(:proxy => "http://<proxy>:<port>");
```

Regarding the functioning of **HTTP.jl**, you might need to modify another option to change the *db/editor.nomics.world* url from *https://* to *http://* (see https://github.com/JuliaWeb/HTTP.jl/pull/390) :
```julia
DBnomics.options("secure", false);
```

#### Set the connection up for a session
The curl connection can be set up for a session by modifying the following package option :
```julia
DBnomics.options("curl_config", h);
```
After configuration, just use the standard functions of **DBnomics.jl** e.g. :
```julia
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
```
This option of the package can be disabled with :
```julia
DBnomics.options("curl_config", nothing);
```

#### Use the connection only for a function call
If a complete configuration is not needed but just an "on the fly" execution, then use the argument `curl_config` of the functions `rdb` and `rdb_...` :
```julia
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN", curl_config = h);
```

### Use the standard functions `readlines` and `download`
To retrieve the data **DBnomics.jl** can also use the standard functions `readlines` and `download`.

#### Set the connection up for a session
To activate this feature for a session, you need to enable an option of the package :
```julia
DBnomics.options("use_readlines", true);
```
And then use the standard function as follows :
```julia
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
```
This configuration can be disabled with :
```julia
DBnomics.options("use_readlines", false);
```

#### Use the connection only for a function call
If you just want to do it once, you may use the argument `use_readlines` of the functions `rdb` and `rdb_...` :
```julia
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN", use_readlines = true);
```

## Transform time series with filters
The **DBnomics.jl** package can interact with the *Time Series Editor* of DBnomics to transform time series by applying filters to them.  
Available filters are listed on the filters page [https://editor.nomics.world/filters](https://editor.nomics.world/filters).

Here is an example of how to proceed to interpolate two annual time series with a monthly frequency, using a spline interpolation:

```julia
filters = Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "spline"));

df = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"], filters = filters);
```

If you want to apply more than one filter, the `filters` argument will be a Tuple of valid filters:
```julia
filter1 = Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "spline"));
filter2 = Dict(:code => "aggregate", :parameters => Dict(:frequency => "bi-annual", :method => "end_of_period"));
filters = (filter1, filter2);

df = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"], filters = filters);
```

The `DataFrame` columns change a little bit when filters are used. There are two new columns:

- `period_middle_day`: the middle day of `original_period` (can be useful when you compare graphically interpolated series and original ones).
- `filtered` (boolean): `true` if the series is filtered, `false` otherwise.

The content of two columns are modified:

- `series_code`: same as before for original series, but the suffix `_filtered` is added for filtered series.
- `series_name`: same as before for original series, but the suffix ` (filtered)` is added for filtered series.

## Transform the `DataFrame` object into a `TimeArray` object
For some analysis, it is more convenient to have a `TimeArray` object instead of a `DataFrame` object. To transform
it, you can use the following functions :
```julia
using DBnomics
using DataFrames
using TimeSeries

function to_namedtuples(x::DataFrames.DataFrame)
    nm = names(x)
    try
        vl = [x[!, col] for col in names(x)]
    catch
        vl = [x[:, col] for col in names(x)]
    end
    nm = tuple(nm...)
    vl = tuple(vl...)

    NamedTuple{nm}(vl)
end

function to_timeseries(
    x::DataFrames.DataFrame,
    index = :period, variable = :series_code, value = :value
)
    x = unstack(x, index, variable, value)
    x = to_namedtuples(x)
    x = TimeArray(x, timestamp = index)
    x
end

rdb("IMF", "BOP", mask = "A.FR+ES.BCA_BP6_EUR")
#> 162×18 DataFrame. Omitted printing of 12 columns
#> │ Row │ @frequency │ FREQ   │ Frequency │ INDICATOR   │ Indicator                          │ REF_AREA │
#> │     │ String     │ String │ String    │ String      │ String                             │ String   │
#> ├─────┼────────────┼────────┼───────────┼─────────────┼────────────────────────────────────┼──────────┤
#> │ 1   │ annual     │ A      │ Annual    │ BCA_BP6_EUR │ Current Account, Total, Net, Euros │ ES       │
#> │ 2   │ annual     │ A      │ Annual    │ BCA_BP6_EUR │ Current Account, Total, Net, Euros │ ES       │
#> │ ... │ ...        │ ...    │ ...       │ ...         │ ...                                │ ...      │
#> │ 161 │ annual     │ A      │ Annual    │ BCA_BP6_EUR │ Current Account, Total, Net, Euros │ FR       │
#> │ 162 │ annual     │ A      │ Annual    │ BCA_BP6_EUR │ Current Account, Total, Net, Euros │ FR       │

to_timeseries(rdb("IMF", "BOP", mask = "A.FR+ES.BCA_BP6_EUR"))
#> 81×2 TimeArray{Union{Missing, Float64},2,Date,Array{Union{Missing, Float64},2}} 1940-01-01 to 2020-01-01
#> │            │ A.ES.BCA_BP6_EUR │ A.FR.BCA_BP6_EUR │
#> ├────────────┼──────────────────┼──────────────────┤
#> │ 1940-01-01 │ missing          │ missing          │
#> │ 1941-01-01 │ missing          │ missing          │
#> │ 1942-01-01 │ missing          │ missing          │
#> │ ...        │ ...              │ ...              │
#> │ 2019-01-01 │ 24899.0          │ -16239.4         │
#> │ 2020-01-01 │ missing          │ missing          │
```

## P.S.
Visit <a href="https://db.nomics.world/" target="_blank">https://db.nomics.world/</a> !
