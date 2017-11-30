#' Delete Data
#'
#' Deletes data in an existing table.
#'
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#' @export
ps_delete_data <- function(table_name, conn = getOption("ps.conn")) {
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables) error("'", table_name, "' is not an existing table")

  dbSendQuery(conn = conn, paste0("DELETE FROM ", table_name))

  invisible(TRUE)
}
