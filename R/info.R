#' Quick dataframe info
#'
#' Returns a list containing information about dataframe columns relevant
#' to SQLite database creation. If column is numeric, integer or POSIXct,
#' function returns number of missing values, class, minimum and maximum values.
#' If column is character, function returns number of missing values, class, and
#' all unique values.
#'
#' @param df A data.frame object.
#' @export
ps_df_info <- function(df){
  check_data(df)

  if(inherits(df, "sf")) {
    sf::st_geometry(df) <- NULL
  }

  lapply(df, function(x){
    if(inherits(x, "numeric") || inherits(x, "integer")  || inherits(x, "POSIXct")){
      list(missing = length(which(is.na(x))),
           class = class(x),
           min = min(x, na.rm = T),
           max = max(x, na.rm = T),
           key = length(unique(x)) == length(x))} else if(inherits(x, "blob")){
             list(missing = length(which(is.na(x))),
                  class = class(x))
           } else {
             list(missing = length(which(is.na(x))),
                  class = class(x),
                  unique = unique(x),
                  key = length(unique(x)) == length(x))
           }

  })
}

#' SQL column info
#'
#' @param table_name A string of the name of the table.
#' @param conn An SQLiteConnection object.
#'
#' @return A data frame with the name of the column and the type.
#' @export
ps_column_info <- function(table_name, conn = getOption("ps.conn")) {
  check_string(table_name)
  check_sqlite_connection(conn)

  if (!dbExistsTable(conn, table_name))
    error("'", table_name, "' is not an existing table")

  result <- dbSendQuery(conn, paste0("SELECT * FROM ", table_name," LIMIT 1"))
  info <- dbColumnInfo(result)
  dbClearResult(result)
  info
}
