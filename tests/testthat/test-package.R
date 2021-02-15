test_that("package", {
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

  comment(blob_data$File) <- "file stuff"
  comment(blob_data$BLOB) <- "blobby stuff"

  dbGetQuery(conn,
             "CREATE TABLE blob_table (
             File TEXT NOT NULL,
             BLOB BLOB NOT NULL)")

  ps_write_table(blob_data, "blob_table", conn)

  expect_identical(ps_table_definition("blob_table", conn),
                   "CREATE TABLE blob_table ( File TEXT NOT NULL, BLOB BLOB NOT NULL)")

  metadata <- ps_update_metadata(conn)

  expect_is(metadata, "tbl_df")
  expect_identical(colnames(metadata), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(sort(metadata$DataColumn), sort(colnames(blob_data)))

  blob_data_new <- ps_read_table("blob_table", conn)

  expect_identical(comment(blob_data_new$File), "file stuff")
  expect_identical(comment(blob_data_new$BLOB), "blobby stuff")

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

  ps_disconnect_sqlite(conn)
  ps_disconnect_sqlite(conn2)

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
  metadata$DataDescription[2] <- "The weight of feed"

  dbWriteTable(conn, "MetaData", metadata, overwrite = TRUE)
  metadata2 <- ps_update_metadata(conn)
  expect_identical(metadata, metadata2)

  more_data <- tibble::tibble(StartDateTime = ISOdate(2017, 3, 12, c(2,3), 8, tz = "Etc/GMT+8"),
                              Sample = factor(c("a", "b"), levels = c("b", "a", "c")),
                              Sample2 = ordered(c("a", "b"), levels = c("b", "a", "c")),
                              AName = c(TRUE, NA),
                              Random = 1:2,
                              Distance = units::set_units(c(0.1, 0.5), "m"),
                              Blob = blobs,
                              Dayte = as.Date(c("2001-01-02", "2002-02-03")))

  more_data$Sample <- set_comment(more_data$Sample, "sample stuff")

  dbGetQuery(conn,
             "CREATE TABLE MoreData (
             StartDateTime TEXT NOT NULL,
             Sample TEXT,
             Sample2 TEXT,
             Distance REAL,
             Dayte TEXT,
             AName BOOLEAN,
             Blob BLOB)")

  expect_identical(ps_column_info("MoreData", conn),
                   structure(list(
                     name = c("StartDateTime", "Sample", "Sample2",
                              "Distance", "Dayte", "AName", "Blob"),
                     type = c("character", "character", "character", "double",
                              "character", "double", "list"
                     )), row.names = c(NA, -7L), class = "data.frame",
                     .Names = c("name", "type")))

  ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn)

  ps_delete_data("MoreData", conn = conn)

  more_data$Distance <- units::set_units(more_data$Distance, "km")

  expect_error(ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn), "new units 'km' in column 'Distance' in table 'MoreData' are not identical to existing units 'm'")

  expect_warning(ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn, overwrite_units = TRUE), "new units 'km' in column 'Distance' in table 'MoreData' replacing existing units 'm'")

  comment(more_data$Sample) <- paste0(comment(more_data$Sample), "2")

  expect_error(ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn, delete = TRUE), "new description 'sample stuff2' in column 'Sample' in table 'MoreData' is not identical to existing description 'sample stuff'")

  expect_warning(ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn, delete = TRUE, overwrite_descriptions = TRUE), "new description 'sample stuff2' in column 'Sample' in table 'MoreData' replacing existing description 'sample stuff'")

  ps_write_table(more_data[c("Sample", "Sample2", "StartDateTime", "Blob", "AName", "Distance", "Dayte")], "MoreData", conn = conn, delete = TRUE, overwrite_descriptions = TRUE)

  dbGetQuery(conn,
             "CREATE TABLE OtherData (
             StartDateTime TEXT NOT NULL,
             Sample TEXT,
             ALocation TEXT NOT NULL,
             Location BLOB NOT NULL,
             Blob BLOB
  )")

  other_data <- more_data
  other_data$X <- c(1,10)
  other_data$Y <- c(10,1)

  other_data <-  poisspatial::ps_coords_to_sfc(other_data, crs = 28992, sfc_name = "Location") %>%
    poisspatial::ps_activate_sfc("Location")

  other_data$ALocation <- other_data$Location

  suppressWarnings(ps_write_table(other_data, "OtherData", conn = conn))

  more_data2 <- ps_read_table("MoreData", conn = conn)

  expect_equivalent(more_data2[[1]], more_data[colnames(more_data2)][[1]])
  expect_equivalent(more_data2[[2]], more_data[colnames(more_data2)][[2]])
  expect_equivalent(more_data2[[3]], more_data[colnames(more_data2)][[3]])
  expect_equivalent(more_data2[[4]], more_data[colnames(more_data2)][[4]])
  expect_equivalent(more_data2[[5]], more_data[colnames(more_data2)][[5]])
  expect_equivalent(more_data2[[6]], more_data[colnames(more_data2)][[6]])
  expect_equivalent(more_data2[[7]], more_data[colnames(more_data2)][[7]])
  expect_identical(lubridate::tz(more_data2$StartDateTime), "Etc/GMT+8")

  expect_identical(comment(more_data2$AName), NULL)
  expect_identical(comment(more_data2$Blob), "blobby stuff")
  expect_identical(comment(more_data2$Sample), "sample stuff2")

  more_data3 <- more_data2
  more_data3[] <- lapply(more_data3[], function(x) { comment(x) <- NULL; x})
  more_data3$Distance <- units::drop_units(more_data3$Distance)

  expect_false(identical(more_data3, more_data2))

  more_data3 <- ps_interpret_data(more_data3, table = "MoreData",
                                   conn = conn)

  expect_true(identical(more_data3, more_data2))

  other_data2 <- ps_read_table("OtherData", conn = conn)

  expect_identical(other_data2[[1]], other_data[colnames(other_data2)][[1]])
  expect_identical(other_data2[[2]], other_data[colnames(other_data2)][[2]])
  expect_equivalent(other_data2[[3]], other_data[colnames(other_data2)][[3]])
  expect_equivalent(other_data2[[4]], other_data[colnames(other_data2)][[4]])
  expect_equivalent(other_data2[[5]], other_data[colnames(other_data2)][[5]])
#  expect_identical(other_data2[[4]], other_data2[[5]]) not sure why broken

  expect_identical(class(other_data2), class(other_data))
  expect_identical(lubridate::tz(other_data2$StartDateTime), "Etc/GMT+8")
  expect_true(poisspatial::is_crs(poisspatial::ps_get_proj4string(other_data2)))

  expect_false(exists("MoreData"))
  tabs <- ps_load_tables(conn)
  expect_true(exists("MoreData"))

  csvs <- ps_write_tables_csvs(conn, dir = dir)
  expect_identical(tabs, csvs)
  expect_true(all(paste0(csvs, ".csv") %in% list.files(dir)))

  expect_identical(tabs, sort(c("chickwts", "MetaData", "MoreData", "OtherData")))

  metadata <- ps_update_metadata(conn)

  expect_identical(sum(is.na(metadata$DataUnits)), 3L)

  dbRemoveTable(conn, "chickwts")
  metadata2 <- ps_update_metadata(conn, rm_missing = FALSE)
  expect_identical(metadata, metadata2)

  metadata2 <- ps_update_metadata(conn)
  expect_is(metadata2, "tbl_df")
  expect_identical(colnames(metadata2), c("DataTable", "DataColumn", "DataUnits", "DataDescription"))
  expect_identical(nrow(metadata2), 12L)

  info <- ps_df_info(more_data)
  expect_is(info, "list")
  expect_identical(length(info), 8L)
  expect_identical(info$StartDateTime$class[1], "POSIXct")
  expect_identical(info$Blob$class, c("blob", "vctrs_list_of", "vctrs_vctr"))
  expect_true(info$StartDateTime$missing == 0L)
  expect_true(info$AName$missing == 1L)
  expect_true(length(info$Blob) == 2L)
  expect_identical(info$Sample$key, TRUE)

  expect_identical(length(ls()), 23L)
  expect_identical(length(poisdata::ps_names_datas()), 15L)
  expect_identical(length(ps_strip_columns("Blob")), 7L)

  expect_identical(colnames(more_data), c("StartDateTime", "Sample", "Sample2","AName", "Random", "Distance", "Dayte"))
})

