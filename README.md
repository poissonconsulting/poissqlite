
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/joethorley/stability-badges#experimental) [![Travis-CI Build Status](https://travis-ci.org/poissonconsulting/poissqlite.svg?branch=master)](https://travis-ci.org/poissonconsulting/poissqlite) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/poissonconsulting/poissqlite?branch=master&svg=true)](https://ci.appveyor.com/project/poissonconsulting/poissqlite) [![Coverage Status](https://img.shields.io/codecov/c/github/poissonconsulting/poissqlite/master.svg)](https://codecov.io/github/poissonconsulting/poissqlite?branch=master) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/poissqlite)](https://cran.r-project.org/package=poissqlite)

poissqlite
==========

An R package to facilitate working with SQLite databases.

Documentation
-------------

### Connection

The `ps_connect_sqlite()` function can be used to connect to an sqlite3 database. By default it switches foreign keys on. The connection can be queried using the functions in the `DBI` package (which is automatically loaded).

``` r
library(poissqlite)
#> Loading required package: DBI
dir <- tempdir()
conn <- ps_connect_sqlite(dir = dir, new = TRUE)
#> Warning in rsqlite_fetch(res@ptr, n = n): Don't need to call dbFetch() for
#> statements, only for queries
print(class(conn))
#> [1] "SQLiteConnection"
#> attr(,"package")
#> [1] "RSQLite"
```

### Working with Blobs

Files and R objects can be added to SQLite databases as storage type [BLOB](https://sqlite.org/datatype3.html).

The `ps_blob_file()` function can be used to convert a file to a `blob` while `ps_deblob_file()` performs the inverse operation, i.e., saves a blob to a file of the original format. `ps_blob_files()` and `ps_deblob_files()` are the equivalent functions for working with multiple files. In addition, the `ps_blob_object()` and `ps_deblob_object()` can be used to convert between an R object and a blob. This is achieved by reading or writing the object as an `.rds` file which means that `ps_deblob_file()` applied to a blob created using `ps_blob_object()` produces the intermediate `.rds` file.

It's important to realize that the `ps_blob` family of functions embed the original file extension in the raw data to ensure the converted files are the original format. A consequence of this is that when deblobbing, file names should not include an extension (file extensions can be removed using `tools::file_path_sans_ext()`). A second consequence is that the `ps_deblob` family of functions will only work on blobs created using the `ps_blob` functions.

``` r
library(readr)

cars <- tibble::as_tibble(datasets::cars)

print(cars)
#> # A tibble: 50 x 2
#>    speed  dist
#>    <dbl> <dbl>
#>  1     4     2
#>  2     4    10
#>  3     7     4
#>  4     7    22
#>  5     8    16
#>  6     9    10
#>  7    10    18
#>  8    10    26
#>  9    10    34
#> 10    11    17
#> # ... with 40 more rows

write_csv(cars, file.path(dir, "cars.csv"))

blob_tibble <- ps_blob_files(dir, pattern = "[.]csv$")

print(blob_tibble)
#> # A tibble: 1 x 2
#>       File          BLOB
#>      <chr>        <blob>
#> 1 cars.csv <blob[378 B]>

dbWriteTable(conn, "blob_table", blob_tibble)

blob_tibble_new <- dbReadTable(conn, "blob_table")

dir_new <- file.path(dir, "new")
dir.create(dir_new)
blobs <- blob_tibble_new$BLOB
names(blobs) <- tools::file_path_sans_ext(blob_tibble_new$File)

ps_deblob_files(blobs, dir = dir_new)

cars_new <- read_csv(file.path(dir_new, "cars.csv"), 
                            col_types = cols(
                              speed = col_double(),
                              dist = col_double()
                            ))

print(cars_new)
#> # A tibble: 50 x 2
#>    speed  dist
#>    <dbl> <dbl>
#>  1     4     2
#>  2     4    10
#>  3     7     4
#>  4     7    22
#>  5     8    16
#>  6     9    10
#>  7    10    18
#>  8    10    26
#>  9    10    34
#> 10    11    17
#> # ... with 40 more rows
```

### Disconnection

``` r
dbDisconnect(conn)
```

Installation
------------

``` r
# install.packages("devtools")
devtools::install_github("poissonconsulting/poissqlite")
```

Contribution
------------

Please report any [issues](https://github.com/poissonconsulting/poissqlite/issues).

[Pull requests](https://github.com/poissonconsulting/poissqlite/pulls) are always welcome.

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/poissonconsulting/poissqlite/blob/master/CONDUCT.md). By participating in this project you agree to abide by its terms.
