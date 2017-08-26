context("sqlite")

test_that("sqlite", {
  dir <- tempdir()
  conn <- ps_connect_sqlite(dir = dir, ask = FALSE)
  expect_is(conn, "SQLiteConnection")

  expect_identical(DBI::dbListTables(conn), character(0))

  blob <- ps_blob_files(dir = file.path(system.file(package = "poissqlite")), recursive = TRUE)

  expect_identical(class(blob), c("tbl_df", "tbl", "data.frame"))
  expect_identical(colnames(blob), c("File", "BLOB"))
  expect_identical(blob$File, c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))
  expect_identical(class(blob$BLOB), "blob")

  dbWriteTable(conn, "blob", blob)
  expect_identical(dbListTables(conn), "blob")

  blob <- dbReadTable(conn, "blob")

  blobs <- blob$BLOB
  names(blobs) <- tools::file_path_sans_ext(blob$File)

  tempdir <- tempdir()
  files <- ps_deblob_files(blobs, tempdir, ask = FALSE)
  expect_identical(files, file.path(c("seb-dalgarno.pdf", "sub/joe-thorley.pdf")))

  conn2 <- ps_connect_sqlite(dir = dir, new = FALSE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn), "blob")

  dbDisconnect(conn)
  dbDisconnect(conn2)

  conn <- ps_connect_sqlite(dir = dir, new = TRUE, ask = FALSE)

  expect_identical(DBI::dbListTables(conn), character(0))
})
