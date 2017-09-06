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

  units <- metadata$DataUnits
  names(units) <- metadata$DataColumn

  units <- units[is_units(units)]
  for (i in seq_along(units)) {
    table[[names(units[i])]] %<>% set_units(units[i])
  }
  wchgeo <- which(poisspatial::is_crs(units))
  if (length(wchgeo)) {
    if (length(wchgeo) != 1) ps_error("table has more than one geometry")
    table %<>% sf::st_sf(geometry = table[[names(units[wchgeo])]])
  }
 table
}
