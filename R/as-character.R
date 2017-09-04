as_character <- function(x, ...) {
  UseMethod("as_character", x)
}

as_character.POSIXt <- function(x, ...) {
  format(x, "%Y-%m-%d %H:%M:%S")
}
