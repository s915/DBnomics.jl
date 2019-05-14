# DBnomics.jl

## DBnomics Julia client (Julia version &ge; 0.6.4)

This package provides you access to DBnomics data series. DBnomics is an open-source project with the goal of aggregating the world's economic data in one location, free of charge to the public. DBnomics covers hundreds of millions of series from international and national institutions (Eurostat, World Bank, IMF, ...).

To use this package, you have to provide the codes of the provider, dataset and series you want. You can retrieve them directly on the <a href="https://db.nomics.world/" target="_blank">website</a>.

To install `DBnomics.jl`, go to the package manager with `]` :

```julia
add https://github.com/s915/DBnomics.jl
```

:warning: If your version of Julia is less than 0.7.0 then the packages
**Missings** and **NamedTuples** are needed. They don't appear in the REQUIRE
file but an error message will come up if these packages aren't installed.

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

1. configuring **curl** of the function `HTTP.get` to use a specific and authorized proxy.

2. using the functions `readlines` and `download` if you have problem with `HTTP.get`.

### Configure **curl** to use a specific and authorized proxy
In **DBnomics**, by default the function `HTTP.get` is used to fetch the data. If a specific proxy must be used, it is possible to define it permanently with the package global variable `curl_config` or on the fly through the argument `curl_config`. In that way the object is passed to the keyword arguments of the `HTTP.get` function.  
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

## P.S.
Visit <a href="https://db.nomics.world/" target="_blank">https://db.nomics.world/</a> :bar_chart: !
