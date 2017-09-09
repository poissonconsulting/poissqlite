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

  more_data <- tibble::tibble(StartDateTime = ISOdate(2001, 6:7, 4, tz = "PST8PDT"),
                              Sample = 1:2)

  dbGetQuery(conn,
             "CREATE TABLE MoreData (
                StartDateTime TEXT NOT NULL,
                Sample INT)")

  ps_write_table(more_data, "MoreData", conn = conn)

  dbGetQuery(conn,
             "CREATE TABLE OtherData (
                StartDateTime TEXT NOT NULL,
                Sample INT,
                geometry TEXT NOT NULL)")

  other_data <- more_data
  other_data$X <- c(1,10)
  other_data$Y <- c(10,1)

  other_data <-  sf::st_as_sf(other_data, coords = c("X", "Y"), crs = 28992)

  ps_write_table(other_data, "OtherData", conn = conn)

  more_data2 <- ps_read_table("MoreData", conn = conn)

  expect_equal(more_data2, more_data)
  expect_identical(lubridate::tz(more_data2$StartDateTime), "PST8PDT")

  other_data2 <- ps_read_table("OtherData", conn = conn)

  expect_equivalent(other_data2, other_data)

  expect_identical(class(other_data2), class(other_data))
  expect_identical(lubridate::tz(other_data2$StartDateTime), "PST8PDT")
  expect_identical(sf::st_crs(other_data2)$epsg, 28992L)

  expect_false(exists("MoreData"))
  tabs <- ps_read_tables(conn)
  expect_true(exists("MoreData"))

  expect_identical(tabs, sort(c("chickwts", "MetaData", "MoreData", "OtherData")))


  metadata <- ps_update_metadata(conn)

  expect_identical(sort(metadata$DataUnits), sort(c(NA, "kg", NA, "PST8PDT",
                                                    "+init=epsg:28992", NA, "PST8PDT")))

  dbRemoveTable(conn, "chickwts")
  metadata2 <- ps_update_metadata(conn, rm_missing = FALSE)
  expect_identical(metadata, metadata2)

  metadata2 <- ps_update_metadata(conn)
  expect_is(metadata2, "tbl_df")
  expect_identical(colnames(metadata2), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata2), 5L)
})
