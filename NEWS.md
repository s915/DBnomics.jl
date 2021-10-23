# Version 0.3.2

* Modification of the regular expression for float values in the function `value_to_float!()`. From `Ref(r"^[0-9]*[[:blank:]]*[0-9]+\.*[0-9]*e*[0-9]*$")` to `Ref(r"^[0-9]*[[:blank:]]*[0-9]+\.*[0-9]*$")` (@tlorans, issue "Error with value_to_float! function #11").
* Add a compat entry for the DataFrames package : 1.2.

# Version 0.3.1

* Change the compat entry for the DataFrames package to 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.20, 0.21, 0.22, 1.0, 1.1.

# Version 0.3.0

* New argument 'query' and 'api_link' for function `rdb()`.
* `rdb_by_api_link()` is deprecated.
* New function `rdb_datasets()` to request the available datasets of the providers.
* New function `rdb_dimensions()` to request the list of the dimensions of the available datasets of the providers.
* New function `rdb_series()` to request the list of the series of the available datasets of the providers.
* New internal function `dot_rdb()`.

# Version 0.2.0

* New filters tool from <https://editor.nomics.world/filters>.
* If the retrieved dataset contains columns with codes (like ISO codes,
  geographic codes, ...), then correspondences are performed to translate
  these codes if possible.

# Version 0.1.0

* First release.
