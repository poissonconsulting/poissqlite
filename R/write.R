#' Write Table
#'
#' Appends a data frame to an existing table in an SQLite database
#' without row names.
#' More importantly it saves the time zone for POSIXct columns
#' in the metadata table and converts the column to a character vector
#' of format `YYYY-mm-dd HH:MM:SS`.
#' It also saves the projection and converts the geometry column to a character
#' vector for sfc columns. And saves any column comments to the DataDescription
#' entry in the metadata table.
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
#' @param delete A flag indicating whether to delete the existing data before appending the data.
#' @param overwrite_units A flag indicating whether to overwrite existing units.
#' @param overwrite_descriptions A flag indicating whether to overwrite existing descriptions.
#' @param rename A function to rename column names in x.
#' @export
ps_write_table <- function(x, table_name, conn = getOption("ps.conn"), delete = FALSE,
                           overwrite_units = FALSE, overwrite_descriptions = FALSE, rename = identity) {
  if (!is.data.frame(x)) error("x must be a data frame")
  check_string(table_name)
  check_flag(delete)
  check_flag(overwrite_units)
  check_flag(overwrite_descriptions)
  check_sqlite_connection(conn)

  if (!dbExistsTable(conn, table_name))
    error("'", table_name, "' is not an existing table")

  if (poisspatial::is.sf(x))
    x %<>% as.data.frame()

  colnames(x) %<>% rename()

  column_names <- dbListFields(conn, table_name)

  missing <- setdiff(column_names, colnames(x))
  if (length(missing)) ps_error("missing column names")

  extra <- setdiff(colnames(x), column_names)
  if (length(extra)) ps_warning("extra column names")

  x[] %<>% purrr::lmap_if(has_comment, ps_update_metadata_description,
                          conn = conn, table_name = table_name, overwrite = overwrite_descriptions)

  x[] %<>% purrr::lmap_if(has_units, ps_update_metadata_units,
                          conn = conn, table_name = table_name, overwrite = overwrite_units)

  x <- x[column_names]

  if(delete) ps_delete_data(table_name, conn = conn)

  dbWriteTable(conn, name = table_name, value = x, row.names = FALSE, append = TRUE)
  invisible(x)
}
