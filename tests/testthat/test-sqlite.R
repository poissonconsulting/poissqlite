context("sqlite")

test_that("sqlite", {
  dir <- tempdir()
  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)
  expect_is(conn, "SQLiteConnection")

  expect_identical(DBI::dbListTables(conn), character(0))

  mtcars <- tibble::as_tibble(datasets::mtcars)
  cars <- tibble::as_tibble(datasets::cars)

  readr::write_csv(mtcars, file.path(dir, "mtcars.csv"))
  dir.create(file.path(dir, "sub"))
  readr::write_csv(cars, file.path(dir, "sub/cars.csv"))

  blob_tibble <- ps_blob_files(dir, pattern = "[.]csv$", recursive = TRUE)

  expect_identical(class(blob_tibble), c("tbl_df", "tbl", "data.frame"))
  expect_identical(colnames(blob_tibble), c("File", "BLOB"))
  expect_identical(blob_tibble$File, c("mtcars.csv", "sub/cars.csv"))
  expect_identical(class(blob_tibble$BLOB), "blob")

  dbWriteTable(conn, "blob_table", blob_tibble)

  blob_tibble_new <- dbReadTable(conn, "blob_table")

  dir_new <- file.path(dir, "new")
  dir.create(dir_new)
  blobs <- blob_tibble_new$BLOB
  names(blobs) <- tools::file_path_sans_ext(blob_tibble_new$File)

  ps_deblob_files(blobs, dir = dir_new, ask = FALSE)

  mtcars_new <- readr::read_csv(file.path(dir_new, "mtcars.csv"))
  cars_new <- readr::read_csv(file.path(dir_new, "sub/cars.csv"))

  expect_equal(mtcars, mtcars_new, check.attributes = FALSE)
  expect_equal(cars, cars_new, check.attributes = FALSE)

  expect_identical(dbListTables(conn), "blob_table")

  conn2 <- ps_connect_sqlite(dir = dir, new = FALSE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn2), "blob_table")

  dbDisconnect(conn)
  dbDisconnect(conn2)

  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn), character(0))
})
