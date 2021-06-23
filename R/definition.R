#' Table Definition
#'
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#'
#' @return A string of the SQL definition of the table.
#' @export
ps_table_definition <- function(table_name, conn = getOption("ps.conn")) {
  chk_string(table_name)
  check_sqlite_connection(conn)

  if (!dbExistsTable(conn, table_name))
    error("'", table_name, "' is not an existing table")

  definition <- dbGetQuery(conn, paste0("SELECT sql FROM sqlite_master WHERE name = '", table_name, "';"))
  definition <- definition[1,1]
  definition <- gsub("\\s{2,}", " ", definition)
  definition
}
