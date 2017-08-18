context("blob")

test_that("blob works", {
  dir <- file.path(system.file(package = "poissqlite"))
  blob <- ps_blob(dir, recursive = TRUE)
  expect_identical(length(blob), 2L)
  expect_identical(names(blob), c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))

  tibble <- ps_blob_to_tibble(blob)

  expect_identical(class(tibble), c("tbl_df", "tbl", "data.frame"))
  expect_identical(colnames(tibble), c("File", "BLOB"))
  expect_identical(tibble$File, c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))
  expect_identical(class(tibble$BLOB), "AsIs")

  names(blob) <- tools::file_path_sans_ext(names(blob))

  tempdir <- tempdir()
  names <- ps_deblob(blob, tempdir)
  expect_identical(names, file.path(tempdir,c("seb-dalgarno.pdf", "sub/joe-thorley.pdf")))
})
