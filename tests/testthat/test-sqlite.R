context("sqlite")

test_that("sqlite", {
  dir <- tempdir()
  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)
  expect_is(conn, "SQLiteConnection")

  expect_identical(DBI::dbListTables(conn), character(0))

  write.csv(datasets::mtcars, file.path(dir, "mtcars.csv"), row.names = FALSE)
  dir.create(file.path(dir, "sub"))
  write.csv(datasets::cars, file.path(dir, "sub/cars.csv"), row.names = FALSE)

  blobs <- ps_blob_files(dir, pattern = "[.]csv$", recursive = TRUE)

  expect_is(blobs, "blob")
  expect_identical(length(blobs), 2L)
  expect_identical(names(blobs), c("mtcars.csv", "sub/cars.csv"))

  blob_data <- data.frame(File = names(blobs), BLOB = blobs, stringsAsFactors = FALSE)

  dbWriteTable(conn, "blob_table", blob_data)

  blob_data_new <- dbReadTable(conn, "blob_table")

  dir_new <- file.path(dir, "new")
  dir.create(dir_new)
  blobs <- blob_data_new$BLOB
  names(blobs) <- tools::file_path_sans_ext(blob_data_new$File)

  ps_deblob_files(blobs, dir = dir_new, ask = FALSE)

  mtcars_new <- read.csv(file.path(dir_new, "mtcars.csv"), stringsAsFactors = FALSE)
  cars_new <- read.csv(file.path(dir_new, "sub/cars.csv"), stringsAsFactors = FALSE)

  expect_equal(cars, cars_new, check.attributes = FALSE)

  expect_identical(dbListTables(conn), "blob_table")

  conn2 <- ps_connect_sqlite(dir = dir, new = FALSE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn2), "blob_table")

  dbDisconnect(conn)
  dbDisconnect(conn2)

  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn), character(0))
})
