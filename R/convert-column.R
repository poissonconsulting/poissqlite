convert_column <- function(x, ...) {
  UseMethod("convert_column", x)
}

convert_column.default <- function(x, ...) {
  as.character(x)
}

convert_column.sfc <- function(x, ...) {
  sf::st_as_text(x)
}

convert_column.POSIXt <- function(x, ...) {
  format(x, "%Y-%m-%d %H:%M:%S")
}

convert_column.logical <- function(x, ...) {
  as.integer(x)
}
