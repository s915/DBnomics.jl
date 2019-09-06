# DBnomics.jl

## DBnomics Julia client (Julia version &ge; 0.7)

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

All the functions, and their names, are derived from the R package <a href="https://github.com/dbnomics/rdbnomics" target="_blank"><b>rdbnomics</b></a>.

## Examples
Fetch time series by `ids` :
```julia
# Fetch one series from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df1 = rdb(ids = "AMECO/ZUTN/EA19.1.0.0.0.ZUTN");

# Fetch two series from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df2 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"]);

# Fetch two series from different datasets of different providers :
df3 = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "IMF/CPI/A.AT.PCPIT_IX"]);
```

In the event that you only use the argument `ids`, you can drop it and run :
```julia
df1 = rdb("AMECO/ZUTN/EA19.1.0.0.0.ZUTN");
```

Fetch time series by `mask` :
```julia
# Fetch one series from dataset 'Consumer Price Index' (CPI) of IMF :
df1 = rdb("IMF", "CPI", mask = "M.DE.PCPIEC_WT");

# Fetch two series from dataset 'Consumer Price Index' (CPI) of IMF :
df2 = rdb("IMF", "CPI", mask = "M.DE+FR.PCPIEC_WT");

# Fetch all series along one dimension from dataset 'Consumer Price Index' (CPI) of IMF :
df3 = rdb("IMF", "CPI", mask = "M..PCPIEC_WT");

# Fetch series along multiple dimensions from dataset 'Consumer Price Index' (CPI) of IMF :
df4 = rdb("IMF", "CPI", mask = "M..PCPIEC_IX+PCPIA_IX");
```

In the event that you only use the arguments `provider_code`, `dataset_code` and `mask`, you can drop the name `mask` and run :
```julia
df1 = rdb("IMF", "CPI", "M.DE.PCPIEC_WT");
```

Fetch time series by `dimensions` :
```julia
# Fetch one value of one dimension from dataset 'Unemployment rate' (ZUTN) of AMECO provider :
df1 = rdb("AMECO", "ZUTN", dimensions = Dict(:geo => "ea12"));
# or
df1 = rdb("AMECO", "ZUTN", dimensions = (geo = "ea12",));
# or
df1 = rdb("AMECO", "ZUTN", dimensions = """{"geo": ["ea19"]}""");

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

Fetch one series from the dataset 'Doing Business' of WB provider with the link :
```julia
df1 = rdb_by_api_link("https://api.db.nomics.world/v22/series/WB/DB?dimensions=%7B%22country%22%3A%5B%22FR%22%2C%22IT%22%2C%22ES%22%5D%7D&q=IC.REG.PROC.FE.NO&observations=1&format=json&align_periods=1&offset=0&facets=0");
```

## Proxy configuration
When using the functions `rdb` or `rdb_...`, if you come across an error concerning your internet connection, you can get round this situation by :

1. configuring **curl** of the function `HTTP.get` or `HTTP.post` to use a specific and authorized proxy.

2. using the functions `readlines` and `download` if you have problem with `HTTP.get`.

### Configure **curl** to use a specific and authorized proxy
In **DBnomics**, by default the function `HTTP.get` or `HTTP.post` is used to fetch the data. If a specific proxy must be used, it is possible to define it permanently with the package global variable `curl_config` or on the fly through the argument `curl_config`. In that way the object is passed to the keyword arguments of the `HTTP.get` or `HTTP.post` function.  
To see the available parameters, visit the website <a href="https://curl.haxx.se/libcurl/c/curl_easy_setopt.html" target="_blank">https://curl.haxx.se/libcurl/c/curl_easy_setopt.html</a>. Once they are chosen, you define the curl object as follows :
```julia
h = Dict(:proxy => "<proxy>", :proxyport => <port>, :proxyusername => "<username>", :proxypassword => "<password>");
```

#### Set the connection up for a session
The curl connection can be set up for a session by modifying the following package option :
```julia
DBnomics.options("curl_config", h);
```
After configuration, just use the standard functions of **DBnomics** e.g. :
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
To retrieve the data **DBnomics** can also use the standard functions `readlines` and `download`.

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

If you want to apply more than one filter, the `filters` argument will be a list of valid filters:
```julia
filters = (Dict(:code => "interpolate", :parameters => Dict(:frequency => "monthly", :method => "spline")), Dict(:code => "aggregate", :parameters => Dict(:frequency => "bi-annual", :method => "end_of_period")));

df = rdb(ids = ["AMECO/ZUTN/EA19.1.0.0.0.ZUTN", "AMECO/ZUTN/DNK.1.0.0.0.ZUTN"], filters = filters);
```

The `DataFrame` columns change a little bit when filters are used. There are two new columns:

- `period_middle_day`: the middle day of `original_period` (can be useful when you compare graphically interpolated series and original ones).
- `filtered` (boolean): `TRUE` if the series is filtered, `FALSE` otherwise.

The content of two columns are modified:

- `series_code`: same as before for original series, but the suffix `_filtered` is added for filtered series.
- `series_name`: same as before for original series, but the suffix ` (filtered)` is added for filtered series.

## Transform the `DataFrame` object into a `TimeArray` object (Julia &ge; 0.7)
For some analysis, it is more convenient to have a `TimeArray` object instead of a `DataFrame` object. To transform
it, you can use the following functions :
```julia
using DBnomics
using DataFrames
using TimeSeries

function to_namedtuples(x::DataFrames.DataFrame)
    nm = names(x)
    try
        vl = [x[:, col] for col in names(x)]
    catch
        vl = [x[!, col] for col in names(x)]
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

rdb("IMF", "CPI", mask = "M.DE+FR.PCPIEC_WT")
#> 570×13 DataFrame. Omitted printing of 9 columns
#> │ Row │ @frequency │ dataset_code │ dataset_name               │ indexed_at                    │
#> │     │ String     │ String       │ String                     │ TimeZones.ZonedDateTime       │
#> ├─────┼────────────┼──────────────┼────────────────────────────┼───────────────────────────────┤
#> │ 1   │ monthly    │ CPI          │ Consumer Price Index (CPI) │ 2019-05-18T02:48:55.708+00:00 │
#> │ 2   │ monthly    │ CPI          │ Consumer Price Index (CPI) │ 2019-05-18T02:48:55.708+00:00 │
#> │ ... │ ...        │ ...          │ ...                        │ ...                           │
#> │ 569 │ monthly    │ CPI          │ Consumer Price Index (CPI) │ 2019-05-18T02:48:55.708+00:00 │
#> │ 570 │ monthly    │ CPI          │ Consumer Price Index (CPI) │ 2019-05-18T02:48:55.708+00:00 │

to_timeseries(rdb("IMF", "CPI", mask = "M.DE+FR.PCPIEC_WT"))
#> 291×2 TimeArray{Union{Missing, Float64},2,Date,Array{Union{Missing, Float64},2}} 1995-01-01 to 2019-03-01
#> │            │ M.DE.PCPIEC_WT │ M.FR.PCPIEC_WT │
#> ├────────────┼────────────────┼────────────────┤
#> │ 1995-01-01 │ missing        │ 20.0           │
#> │ 1995-02-01 │ missing        │ 20.0           │
#> │ ...        │ ...            │ ...            │
#> │ 2019-02-01 │ 30.1           │ 25.8           │
#> │ 2019-03-01 │ 30.1           │ 25.8           │
```

## P.S.
Visit <a href="https://db.nomics.world/" target="_blank">https://db.nomics.world/</a> :bar_chart: !
