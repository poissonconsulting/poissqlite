context("metadata")

test_that("metadata", {
  dir <- tempdir()
  conn <- ps_connect_sqlite("test3", dir = dir, new = TRUE, ask = FALSE)

  expect_is(conn, "SQLiteConnection")

  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata), 0L)

  dbWriteTable(conn, "mtcars", datasets::mtcars)
  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(metadata$DataColumn, sort(colnames(datasets::mtcars)))

  dbWriteTable(conn, "chickwts", datasets::chickwts)

  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata), 13L)

  dbRemoveTable(conn, "mtcars", datasets::mtcars)

  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(metadata$DataColumn, sort(colnames(datasets::chickwts)))

  metadata$DataUnits[2] <- "kg"

  dbWriteTable(conn, "MetaData", metadata, overwrite = TRUE)
  metadata2 <- ps_update_metadata(conn)
  expect_identical(metadata, metadata2)
  dbRemoveTable(conn, "chickwts")
  metadata2 <- ps_update_metadata(conn, rm_missing = FALSE)
  expect_identical(metadata, metadata2)

  metadata2 <- ps_update_metadata(conn)
  expect_is(metadata2, "tbl_df")
  expect_identical(colnames(metadata2), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata2), 0L)
})
