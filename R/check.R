check_blob <- function(x, x_name = substitute(x)) {
  if (!is.character(x_name))
    x_name <- deparse(x_name)
  if (!is.raw(x)) error(x_name, " must be an object of class raw")
  x
}
