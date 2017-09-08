#' Read Table
#'
#' Returns a table in an SQLite database as a tibble or sf object.
#'
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#' @export
ps_read_table <- function(table_name, conn) {
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables)
    error("'", table_name, "' is not an existing table")

  table <- dbReadTable(conn, name = table_name) %>%
    tibble::as_tibble()

  metadata <- ps_update_metadata(conn, rm_missing = FALSE)
  metadata <- metadata[metadata$DataTable == table_name,]
  metadata <- metadata[!is.na(metadata$DataUnits),]
  metadata <- metadata[vapply(metadata$DataUnits, is_units, TRUE),]

  units <- metadata$DataUnits
  names(units) <- metadata$DataColumn

  for (i in seq_along(units)) {
    table[[names(units[i])]] %<>% set_units(units[i])
  }
  wchcrs <- which(vapply(units, poisspatial::is_crs, TRUE))
  if (length(wchcrs)) {
    table %<>% sf::st_sf(geometry = table[[names(units[wchcrs])]])
    class(table) <- c("sf", "tbl_df", "tbl", "data.frame")
  } else
    table %<>% tibble::as_tibble()
 table
}

#' Read Tables
#'
#' Assigns tables in an SQLite database to global environment
#' as tibble or sf objects.
#'
#' @param conn An SQLiteConnection object.
#' @param rename A function to alter the SQLite database table names.
#' @export
ps_read_tables <- function(conn, rename = identity) {
  check_sqlite_connection(conn)

  tablenames <- DBI::dbListTables(conn)

  invisible(lapply(tablenames, function(x){
    assign(rename(x), ps_read_table(x, conn), envir = globalenv())
  }))
}





