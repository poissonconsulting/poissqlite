context("blob")

test_that("blob works", {
  dir <- file.path(system.file(package = "poissqlite"))
  blob <- ps_blob(dir)
  expect_identical(length(blob), 2L)
  expect_identical(names(blob), c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))

  names(blob) <- tools::file_path_sans_ext(names(blob))

  names <- ps_deblob(blob, tempdir())
  expect_identical(names, c("seb-dalgarno.pdf", "sub/joe-thorley.pdf"))
})
