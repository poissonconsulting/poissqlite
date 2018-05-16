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

ps_update_metadata_units <- function(x, conn, table_name, overwrite) {

  metadata <- ps_update_metadata(conn, rm_missing = FALSE)

  column_name <- colnames(x)
  units <- magrittr::extract2(x, 1) %>%
    get_units()

  wch <- which(metadata$DataTable == table_name & metadata$DataColumn == column_name)

  if (length(wch)) {
    if(is.na(metadata$DataUnits[wch])) {
      metadata$DataUnits[wch] <- units
    } else if(!identical(units, metadata$DataUnits[wch])) {
      if(overwrite) {
        warning("new units '", sub("unit:\\s*", "", units), "' in column '", column_name,
                "' in table '", table_name , "' replacing existing units '",
                sub("unit:\\s*", "", metadata$DataUnits[wch]), "'", call. = FALSE)
        metadata$DataUnits[wch] <- units
      } else {
        stop("new units '", sub("unit:\\s*", "", units), "' in column '", column_name,
             "' in table '", table_name , "' are not identical to existing units '",
             sub("unit:\\s*", "", metadata$DataUnits[wch]), "'", call. = FALSE)
      }
    }
  } else {
    new <- tibble::tibble(DataTable = table_name, DataColumn = column_name,
                          DataUnits = units, DataDescription = NA_character_)
    metadata %<>% rbind(new)
  }

  metadata <- metadata[order(metadata$DataTable, metadata$DataColumn),]

  dbWriteTable(conn, name = "MetaData", value = metadata,
               overwrite = TRUE, row.names = FALSE)

  info <- ps_column_info(table_name, conn)

  type <- info$type[info$name == column_name]

  x[[1]] %<>% convert_column(type = type)
  x
}

ps_update_metadata_description <- function(x, conn, table_name) {

  metadata <- ps_update_metadata(conn, rm_missing = FALSE)

  column_name <- colnames(x)
  description <- magrittr::extract2(x, 1) %>%
    comment() %>% unname()

  wch <- which(metadata$DataTable == table_name & metadata$DataColumn == column_name)

  if (length(wch)) {
    metadata$DataDescription[wch] <- description
  } else {
    new <- tibble::tibble(DataTable = table_name, DataColumn = column_name,
                          DataUnits = NA_character_, DataDescription = description)
    metadata %<>% rbind(new)
  }

  metadata <- metadata[order(metadata$DataTable, metadata$DataColumn),]

  dbWriteTable(conn, name = "MetaData", value = metadata,
               overwrite = TRUE, row.names = FALSE)
  x
}


#' Update MetaData Table
#'
#' Updates the MetaData table in an SQLite database.
#' Creates a new one if absent. The MetaData and Log tables are ignored.
#' Existing DataUnits and DataDescription values are preserved.
#'
#' @param conn An SQLiteConnection object.
#' @param rm_missing A flag indicating whether to remove rows that no longer correspond to a column in a table.
#' @return An invisible tibble of the new MetaData table.
#' @export
ps_update_metadata <- function(conn = getOption("ps.conn"), rm_missing = TRUE) {
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

    check_colnames(metadata_table, c("DataTable", "DataColumn", "DataUnits", "DataDescription"),
                   exclusive = TRUE, order = TRUE, x_name = "MetaData table")

    check_data(metadata_table, values = list(DataTable = "",
                                             DataColumn = "",
                                             DataUnits = c("", NA),
                                             DataDescription = c("", NA)))

    metadata$DataUnits <- NULL
    metadata$DataDescription <- NULL

    metadata %<>% merge(metadata_table, all.x = TRUE, all.y = !rm_missing,
                        by = c("DataTable", "DataColumn"))
  }

  metadata <- metadata[order(metadata$DataTable, metadata$DataColumn),]

  dbWriteTable(conn, name = "MetaData", value = metadata,
               overwrite = TRUE, row.names = FALSE)

  return(invisible(tibble::as_tibble(metadata)))
}
