check_sqlite_connection <- function(x, x_name = substitute(x)) {
  if (!is.character(x)) x_name %<>% deparse()
  if (!is_sqlite_connection(x))
    error(x_name, " must an SQLiteConnection object")
  invisible(x)
}
