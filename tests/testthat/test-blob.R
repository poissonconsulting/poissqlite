context("blob")

test_that("blob works", {
  dir <- file.path(system.file(package = "poissqlite"))
  blob <- ps_blob_files(dir, recursive = TRUE)

  expect_identical(class(blob), c("tbl_df", "tbl", "data.frame"))
  expect_identical(colnames(blob), c("File", "BLOB"))
  expect_identical(blob$File, c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))
  expect_identical(class(blob$BLOB), "AsIs")

  blobs <- blob$BLOB
  names(blobs) <- tools::file_path_sans_ext(blob$File)

  tempdir <- tempdir()
  files <- ps_deblob_files(blobs, tempdir, ask = FALSE)
  expect_identical(files, file.path(c("seb-dalgarno.pdf", "sub/joe-thorley.pdf")))
})
