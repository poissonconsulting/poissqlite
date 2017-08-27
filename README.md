
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
conn <- ps_connect_sqlite(dir = tempdir(), new = TRUE)
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

It's important to realize that the `ps_blob` family of functions embed the original file extension in the raw data to ensure the converted files are the original format. A consequence is that the `ps_deblob` family of functions will only work on blobs created using the `ps_blob` functions.

``` r
print(head(datasets::cars))
#>   speed dist
#> 1     4    2
#> 2     4   10
#> 3     7    4
#> 4     7   22
#> 5     8   16
#> 6     9   10

write.csv(datasets::cars, file.path(tempdir(), "cars.csv"), row.names = FALSE)
dir.create(file.path(tempdir(), "sub"))
write.csv(datasets::chickwts, file.path(tempdir(), "sub/chickwts.csv"), row.names = FALSE)

blobs <- ps_blob_files(tempdir(), pattern = "[.]csv$", recursive = TRUE)

print(blobs)
#>         cars.csv sub/chickwts.csv 
#>      blob[382 B]    blob[1,130 B]

blob_data <- data.frame(File = names(blobs), BLOB = blobs)

dbWriteTable(conn, "blob_table", blob_data)

blob_data_new <- dbReadTable(conn, "blob_table")

blobs <- blob_data_new$BLOB
names(blobs) <- blob_data_new$File 

dir.create(file.path(tempdir(), "new"))
ps_deblob_files(blobs, dir = file.path(tempdir(), "new"), ask = FALSE)

cars_new <- read.csv(file.path(tempdir(), "new", "cars.csv")) 
print(head(cars_new))
#>   speed dist
#> 1     4    2
#> 2     4   10
#> 3     7    4
#> 4     7   22
#> 5     8   16
#> 6     9   10
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
