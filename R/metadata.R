create_metadata <- function(conn, tables) {

  if (!length(tables)) {
    return(tibble::tibble(DataTable = character(0), DataColumn = character(0),
                          DataUnits = character(0), DataDescription = character(0)))
  }

  columns <- lapply(tables, function(name, conn) {dbListFields(conn, name)}, conn = conn)

  names(columns) <- tables

  metadata <- purrr::imap(columns, function(columns, name) {
    tibble::tibble(DataTable = name, DataColumn = columns,
                   DataUnits = NA_character_, DataDescription = NA_character_)
  }) %>%
    do.call(rbind, .)

  metadata <- metadata[order(metadata$DataTable, metadata$DataColumn),]
  metadata
}

#' Update MetaData Table
#'
#' Updates the MetaData table in an SQLite database.
#' Creates a new one if absent. The MetaData and Log tables are ignored.
#' Existing DataUnits and DataDescription values are preserved.
#'
#' @param conn A SQLiteConnection object.
#' @param rm_missing A flag indicating whether to remove rows that no longer correspond to a column in a table.
#' @return An invisible tibble of the new MetaData table.
#' @export
ps_update_metadata <- function(conn, rm_missing = TRUE) {
  check_sqlite_connection(conn)
  check_flag(rm_missing)

  tables <- dbListTables(conn)

  is_metadata_table <- "MetaData" %in% tables

  tables <- tables[!tables %in% c("Log", "MetaData")]

  metadata <- create_metadata(conn, tables)

  if (!is_metadata_table) {
    dbGetQuery(conn,
               "CREATE TABLE MetaData (
                DataTable TEXT NOT NULL,
                DataColumn TEXT NOT NULL,
                DataUnits TEXT,
                DataDescription TEXT,
                PRIMARY KEY (DataTable, DataColumn))"
    )
  } else {
    metadata_table <- dbReadTable(conn, "MetaData")

    check_cols(metadata_table, c("DataTable", "DataColumn", "DataUnits", "DataDescription"),
               exclusive = TRUE, ordered = TRUE, data_name = "MetaData table")

    check_data1(metadata_table, values = list(DataTable = "", DataColumn = "",
                                              DataUnits = c("", NA),
                                              DataDescription = c("", NA)))

    metadata$DataUnits <- NULL
    metadata$DataDescription <- NULL

    metadata %<>% merge(metadata_table, all.x = TRUE, all.y = !rm_missing,
                        by = c("DataTable", "DataColumn"))
  }
  dbWriteTable(conn, name = "MetaData", value = metadata,
               overwrite = TRUE, row.names = FALSE)

  return(invisible(tibble::as_tibble(metadata)))
}
