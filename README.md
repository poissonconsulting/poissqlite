
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/joethorley/stability-badges#experimental) [![Travis-CI Build Status](https://travis-ci.org/poissonconsulting/poissqlite.svg?branch=master)](https://travis-ci.org/poissonconsulting/poissqlite) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/poissonconsulting/poissqlite?branch=master&svg=true)](https://ci.appveyor.com/project/poissonconsulting/poissqlite) [![Coverage Status](https://img.shields.io/codecov/c/github/poissonconsulting/poissqlite/master.svg)](https://codecov.io/github/poissonconsulting/poissqlite?branch=master) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/poissqlite)](https://cran.r-project.org/package=poissqlite)

poissqlite
==========

An R package to facilitate working with SQLite databases.

Installation
------------

``` r
# install.packages("devtools")
devtools::install_github("poissonconsulting/poissqlite")
```

Demonstration
-------------

### BLOBs

Files can be added to SQLite databases as storage type [BLOB](https://sqlite.org/datatype3.html).

The `ps_blob_file()` function can be used to convert a file to a blob (R object of class raw) while `ps_deblob_file()` performs the inverse operation, i.e., saves a blob to a file of the original format. `ps_blob_files()` and `ps_deblob_files()` are the equivalent functions for working with multiple files. In addition, the `ps_blob_object()` and `ps_deblob_object()` can be used to convert between an R object and a blob. This is achieved by reading or writing the object as an `.rds` file which means that `ps_deblob_file()` applied to a blob created using `ps_blob_object()` saves the intermediate `.rds` file.

It's important to realize that the `ps_blob` family of functions embed the original file extension in the raw data to ensure the converted files are the original format. A consequence of this is that when deblobbing, file names should not include an extension (file extensions can be removed using `tools::file_path_sans_ext()`). A second consequence is that the `ps_deblob` family of functions will only work on blobs created using `ps_blob`.

``` r
library(poissqlite)
mat <- matrix(1:9, nrow = 3)
blob <- ps_blob_object(mat)
print(blob)
#>   [1] 58 0a 00 00 00 02 00 03 04 01 00 02 03 00 00 00 02 13 00 00 00 01 00
#>  [24] 00 00 0d 00 00 00 13 00 08 8b 1f 00 00 00 00 e0 8b 03 00 60 60 60 62
#>  [47] 61 66 60 62 06 62 60 64 04 81 79 31 82 33 10 27 40 18 19 c5 cc 40 2c
#>  [70] 82 40 6c c4 0a 1c c4 0e cc 4c 2c 35 10 60 2c 75 60 99 29 cc f5 17 8a
#>  [93] 40 b9 ff 08 1b 49 05 8a 00 03 00 61 5b f9 00 00 04 02 00 00 00 01 00
#> [116] 04 00 09 00 00 00 05 6e 61 6d 65 73 00 00 00 10 00 00 00 01 00 04 00
#> [139] 09 00 00 00 03 72 64 73 00 00 00 fe
ps_deblob_object(blob)
#>      [,1] [,2] [,3]
#> [1,]    1    4    7
#> [2,]    2    5    8
#> [3,]    3    6    9
```

Contribution
------------

Please report any [issues](https://github.com/poissonconsulting/poissqlite/issues).

[Pull requests](https://github.com/poissonconsulting/poissqlite/pulls) are always welcome.

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
