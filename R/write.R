#' Write Table
#'
#' Appends a data frame to an existing table in an SQLite database
#' without row names.
#' More importantly it saves the time zone for POSIXct columns
#' in the metadata table and converts the column to a character vector
#' of format `YYYY-mm-dd HH:MM:SS`.
#' \code{\link{ps_read_table}} looks up the time zone and
#' converts the column back to a POSIXct vector with the original timezone.
#'
#'
#' @param x The data frame.
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#' @export
ps_write_table <- function(x, table_name, conn) {
  if (!is.data.frame(x)) error("x must be a data frame")
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables) error("'", table_name, "' is not an existing table")

  x[] %<>% purrr::lmap_if(has_units, ps_update_metadata_units,
                          conn = conn, table_name = table_name)

  dbWriteTable(conn, name = table_name, value = x, row.names = FALSE, append = TRUE)
}
