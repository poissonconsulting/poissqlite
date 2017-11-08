#' Opens a connection to an sqlite database.
#'
#' The connection can be queried and closed using the functions
#' in the \code{DBI} package.
#'
#' @param file A string of the name of the file (without the file extension .sqlite).
#' @param dir A string of the directory.
#' @param new A flag indicating whether to enforce connection to an existing database (FALSE) or connection to a new database (TRUE).
#' @param foreign_keys A flag indicating whether to switch foreign keys on.
#' @param ask A flag indicating whether to ask before creating a new directory.
#' @export
ps_connect_sqlite <- function(file = "database", dir = ".", new = NA,
                              foreign_keys = TRUE,
                              ask = getOption("poissqlite.ask", TRUE)) {
  check_string(file)
  check_string(dir)
  check_scalar(new, c(TRUE, NA))
  check_flag(foreign_keys)
  check_flag(ask)

  file %<>%
    file.path(dir, .)

  if(identical(tools::file_ext(file), ""))
    file %<>% paste0(".sqlite")

  if (identical(new, FALSE) && !file.exists(file))
    error("database `", file, "` does not exist")

  if (identical(new, TRUE) && file.exists(file))
    file.remove(file)

  if (!poisutils::ps_create_dir(dir, ask)) error("dir '", dir, "' does not exist")

  conn <- DBI::dbConnect(RSQLite::SQLite(), file)
  if (foreign_keys) DBI::dbGetQuery(conn, "PRAGMA foreign_keys = ON;")
  conn
}
