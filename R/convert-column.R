convert_column <- function(x, ...) {
  UseMethod("convert_column", x)
}

convert_column.default <- function(x, ...) {
  as.character(x)
}

convert_column.sfc <- function(x, type = "list", ...) {
  if(type == "character") return(sf::st_as_text(x))
  if(type == "list") return(sf::st_as_binary(x, precision = 0, endian = "little"))
  error("type '", type, "' not recognised for sfc objects")
}

convert_column.POSIXt <- function(x, ...) {
  format(x, "%Y-%m-%d %H:%M:%S")
}

convert_column.logical <- function(x, ...) {
  as.integer(x)
}
