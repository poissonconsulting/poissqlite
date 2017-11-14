#' Read Table
#'
#' Returns a table in an SQLite database as a tibble or sf object.
#'
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#' @export
ps_read_table <- function(table_name, conn = getOption("ps.conn")) {
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables)
    error("'", table_name, "' is not an existing table")

  table <- dbReadTable(conn, name = table_name) %>%
    tibble::as_tibble()

  metadata <- ps_update_metadata(conn, rm_missing = FALSE)
  metadata <- metadata[metadata$DataTable == table_name,]
  metadata %<>% as.data.frame()
  rownames(metadata) <- metadata$DataColumn
  metadata <- metadata[colnames(table),]
  metadata <- metadata[!is.na(metadata$DataUnits),]
  metadata <- metadata[vapply(metadata$DataUnits, is_units, TRUE),]

  units <- metadata$DataUnits
  names(units) <- metadata$DataColumn

  for (i in seq_along(units)) {
    table[[names(units[i])]] %<>% set_units(units[i])
  }

  wchcrs <- which(vapply(units, poisspatial::is_crs, TRUE))
  if (length(wchcrs)) {
    table %<>% poisspatial::ps_activate_sfc(sfc_name = names(units[wchcrs[length(wchcrs)]]))
  }

 table
}

#' Read Tables
#' @inheritParams ps_load_tables
#' @export
ps_read_tables <- function(conn = getOption("ps.conn"), rename = identity, envir = parent.frame()) {
  .Deprecated("ps_load_tables")

  ps_load_tables()
}

#' Load Tables
#'
#' Assigns tables in an SQLite database to environment
#' as tibble or sf objects (if geometry column).
#'
#' @param conn An SQLiteConnection object.
#' @param rename A function to alter the SQLite database table names.
#' @param envir The environment to assign the tables to.
#' @return An invisible vector of table names.
#' @export
ps_load_tables <- function(conn = getOption("ps.conn"), rename = identity, envir = parent.frame()) {
  check_sqlite_connection(conn)

  tables <- DBI::dbListTables(conn) %>%
    sort()

  tables %>%
    stats::setNames(., rename(.)) %>%
    purrr::map(ps_read_table, conn = conn) %>%
    purrr::imap(function(x, name) assign(name, x, envir = envir))

  invisible(tables)
}

