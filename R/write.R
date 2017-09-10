#' Write Table
#'
#' Appends a data frame to an existing table in an SQLite database
#' without row names.
#' More importantly it saves the time zone for POSIXct columns
#' in the metadata table and converts the column to a character vector
#' of format `YYYY-mm-dd HH:MM:SS`.
#' It also saves the projection and converts the geometry column to a character
#' vector for sfc columns.
#'
#' \code{\link{ps_read_table}} looks up the time zone and projection and
#' converts the column back to a POSIXct vector with the original timezone
#' or sfc column with projection.
#'
#' The function is also agnostic as to the order of the columns.
#'
#' @param x The data frame.
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#' @param rename A function to rename column names in x.
#' @export
ps_write_table <- function(x, table_name, conn, rename = identity) {
  if (!is.data.frame(x)) error("x must be a data frame")
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables) error("'", table_name, "' is not an existing table")

  if (poisspatial::is.sf(x))
    x %<>% as.data.frame()

  colnames(x) %<>% rename()

  column_names <- dbListFields(conn, table_name)

  if (!identical(sort(colnames(x)), sort(column_names)))
    error("non-matching column names")

  x[] %<>% purrr::lmap_if(has_units, ps_update_metadata_units,
                          conn = conn, table_name = table_name)

  x <- x[column_names]

  dbWriteTable(conn, name = table_name, value = x, row.names = FALSE, append = TRUE)
}
