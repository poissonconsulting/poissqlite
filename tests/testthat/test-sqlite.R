context("sqlite")

test_that("sqlite", {
  dir <- tempdir()
  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)
  expect_is(conn, "SQLiteConnection")

  expect_identical(dbListTables(conn), character(0))

  metadata <- ps_update_metadata(conn)

  expect_identical(dbListTables(conn), "MetaData")

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata), 0L)

  write.csv(datasets::mtcars, file.path(dir, "mtcars.csv"), row.names = FALSE)
  dir.create(file.path(dir, "sub"))
  write.csv(datasets::cars, file.path(dir, "sub/cars.csv"), row.names = FALSE)

  blobs <- ps_blob_files(dir, pattern = "[.]csv$", recursive = TRUE)

  expect_is(blobs, "blob")
  expect_identical(length(blobs), 2L)
  expect_identical(names(blobs), c("mtcars.csv", "sub/cars.csv"))

  blob_data <- data.frame(File = names(blobs), BLOB = blobs, stringsAsFactors = FALSE)

  dbGetQuery(conn,
             "CREATE TABLE blob_table (
                File TEXT NOT NULL,
                BLOB BLOB NOT NULL)")

  ps_write_table(blob_data, "blob_table", conn)

  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(sort(metadata$DataColumn), sort(colnames(blob_data)))

  blob_data_new <- ps_read_table("blob_table", conn)

  expect_equivalent(blob_data, blob_data_new)

  dir_new <- file.path(dir, "new")
  dir.create(dir_new)
  blobs <- blob_data_new$BLOB
  names(blobs) <- blob_data_new$File

  ps_deblob_files(blobs, dir = dir_new, ask = FALSE)

  mtcars_new <- read.csv(file.path(dir_new, "mtcars.csv"), stringsAsFactors = FALSE)
  cars_new <- read.csv(file.path(dir_new, "sub/cars.csv"), stringsAsFactors = FALSE)

  expect_equal(cars, cars_new, check.attributes = FALSE)

  expect_identical(sort(dbListTables(conn)), sort(c("blob_table", "MetaData")))

  conn2 <- ps_connect_sqlite(dir = dir, new = FALSE, ask = FALSE)

  expect_identical(sort(dbListTables(conn2)), sort(c("blob_table", "MetaData")))

  dbDisconnect(conn)
  dbDisconnect(conn2)

  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)

  expect_identical(dbListTables(conn), character(0))

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
                              Sample = factor(c("a", "b"), levels = c("b", "a", "c")),
                              Blob = blobs)

  dbGetQuery(conn,
             "CREATE TABLE MoreData (
                StartDateTime TEXT NOT NULL,
                Sample TEXT,
                Blob BLOB)")

  ps_write_table(more_data[c("Sample", "StartDateTime", "Blob")], "MoreData", conn = conn)

  dbGetQuery(conn,
             "CREATE TABLE OtherData (
                StartDateTime TEXT NOT NULL,
                Sample TEXT,
                ALocation TEXT NOT NULL,
                Location TEXT NOT NULL,
                Blob BLOB
                )")

  other_data <- more_data
  other_data$X <- c(1,10)
  other_data$Y <- c(10,1)

  other_data <-  poisspatial::ps_coords_to_sfc(other_data, crs = 28992, new_name = "Location") %>%
    poisspatial::ps_set_sf("Location")

  other_data$ALocation <- other_data$Location

  ps_write_table(other_data, "OtherData", conn = conn)

  more_data2 <- ps_read_table("MoreData", conn = conn)

  expect_equivalent(more_data2, more_data)
  expect_identical(lubridate::tz(more_data2$StartDateTime), "PST8PDT")

  other_data2 <- ps_read_table("OtherData", conn = conn)

  expect_equivalent(other_data2, other_data)

  expect_identical(class(other_data2), class(other_data))
  expect_identical(lubridate::tz(other_data2$StartDateTime), "PST8PDT")
  expect_true(poisspatial::is_crs(poisspatial::ps_get_proj4string(other_data2)))

  expect_false(exists("MoreData"))
  tabs <- ps_read_tables(conn)
  expect_true(exists("MoreData"))

  expect_identical(tabs, sort(c("chickwts", "MetaData", "MoreData", "OtherData")))

  metadata <- ps_update_metadata(conn)

  expect_identical(sum(is.na(metadata$DataUnits)), 3L)

  dbRemoveTable(conn, "chickwts")
  metadata2 <- ps_update_metadata(conn, rm_missing = FALSE)
  expect_identical(metadata, metadata2)

  metadata2 <- ps_update_metadata(conn)
  expect_is(metadata2, "tbl_df")
  expect_identical(colnames(metadata2), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata2), 8L)
})
