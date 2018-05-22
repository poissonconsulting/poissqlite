#' Interpret Data
#'
#' Takes a data frame and sets the units and columns for columns which appear
#' in the metadata for table table_name.
#'
#' @inheritParams ps_read_table
#' @param x A data frame of columns to interpret.
#'
#' @return The original data frame with units and column comments.
#' @export
ps_interpret_data <- function(x, table_name, conn = getOption("ps.conn")) {
  check_data(x)
  check_string(table_name)
  check_sqlite_connection(conn)

  tables <- dbListTables(conn)
  if (!table_name %in% tables)
    error("'", table_name, "' is not an existing table")

  if(!ncol(x)) return(x)

  metadata <- ps_update_metadata(conn, rm_missing = FALSE)
  metadata <- metadata[metadata$DataTable == table_name,]
  metadata %<>% as.data.frame()
  rownames(metadata) <- metadata$DataColumn

  missing <- colnames(x)[!colnames(x) %in% rownames(metadata)]

  if(length(missing)) {
    warning("the following columns are not in metadata:",
            poisutils::ps_punctuate(missing, "and"), call. = FALSE)
  }

  metadata <- metadata[rownames(metadata) %in% colnames(x),]

  metadata_units <- metadata[!is.na(metadata$DataUnits),]
  metadata_units <- metadata_units[vapply(metadata_units$DataUnits, is_units, TRUE),]

  units <- metadata_units$DataUnits
  names(units) <- metadata_units$DataColumn

  for (i in seq_along(units)) {
    if(has_units(x[[names(units[i])]]) &&
       get_units(x[[names(units[i])]]) != units[i]) {
      stop("units '", get_units(x[[names(units[i])]]),
           "' in column '", names(units[i]),
           "' are inconsistent with metadata units '", units[i],
           "'", call. = FALSE)
    }
    x[[names(units[i])]] %<>% set_units(units[i])
  }

  wchcrs <- which(vapply(units, poisspatial::is_crs, TRUE))
  if (length(wchcrs)) {
    x %<>% poisspatial::ps_activate_sfc(sfc_name = names(units[wchcrs[length(wchcrs)]]))
  }

  metadata_description <- metadata[!is.na(metadata$DataDescription),]
  descriptions <- metadata_description$DataDescription
  names(descriptions) <- metadata_description$DataColumn

  for (i in seq_along(descriptions)) {
    comment(x[[names(descriptions[i])]]) <- unname(descriptions[i])
  }
  x
}

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

  if(table_name != "metadata") {
    table <- ps_interpret_data(table, table_name = table_name, conn = conn)
  }
  table
}

#' Read Tables
#' @inheritParams ps_load_tables
#' @export
ps_read_tables <- function(conn = getOption("ps.conn"), rename = identity, envir = parent.frame()) {
  .Deprecated("ps_load_tables") # 2017-11-14

  ps_load_tables(conn = conn, rename = rename, envir = envir)
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

