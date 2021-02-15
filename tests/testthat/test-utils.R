test_that("utils", {
  expect_identical(get_units(factor(c("a", "b"))), "levels: c('a', 'b')")
  expect_identical(get_levels("c('a', 'b')"), c("a", "b"))
  expect_true(is_levels("c('a', 'b')"))
  expect_false(is_levels("cc('a', 'b')"))
})
