is.blob <- function(x) inherits(x, "blob")
is.POSIXct <- function(x) inherits(x, "POSIXct")
is.Date <- function(x) inherits(x, "Date")

get_class <- function(x){
  if(is.Date(x)) return("TEXT")
  if(is.POSIXct(x)) return("TEXT")
  if(is.integer(x)) return("INTEGER")
  if(is.double(x)) return("REAL")
  if(is.logical(x)) return("BOOLEAN")
  if(is.blob(x)) return("BLOB")
  "TEXT"
}

get_null <- function(x){
  ifelse(any(is.na(x)), "", " NOT NULL")
}

translate_class <- function(x, name){
  paste0(name, " ", get_class(x), get_null(x))
}

translate_checks <- function(x, name){
  if(is.Date(x))
    return(paste0("LENGTH(", name, ") == 10 AND\n DATE(", name, ") IS NOT NULL AND\n", name, " >= '", min(x, na.rm = TRUE), "' "))
  if(is.POSIXct(x))
    return(paste0("LENGTH(", name, ") == 19 AND\n DATETIME(", name, ") IS NOT NULL AND\n", name, " >= '", min(x, na.rm = TRUE), "' "))
  if(is.numeric(x))
    return(paste0(name, " >= ", min(x, na.rm = TRUE), " AND ", name, " <= ", max(x, na.rm = TRUE), " "))
  if(is.factor(x))
    return(paste0(name, " IN (", paste0("'", levels(x), "'", collapse = ", "), ") "))
  if(is.logical(x))
    return(paste0(name, " IN ('0', '1') "))
}

translate_unique <- function(x, name){
  if(!any(duplicated(x)))
    return(paste0("UNIQUE (", name, "),\n"))
}

translate_sql <- function(data, fun, collapse = ",\n"){
  sql <- mapply(function(x, y) fun(x, y), data, names(data))
  sql <- setNames(sql, seq_along(sql))
  sql <- Filter(Negate(is.null), setNames(sql, seq_along(sql)))
  if(!length(sql))
    sql <- NULL
  sql %>% paste0(collapse = collapse)
}

#' Find primary key
#'
#' Uses a simple algorithm to search for a likely primary key.
#'
#' @param data A data.frame.
#' @return A vector of column names
#' @export
ps_find_key <- function(data) {
  for (i in seq_along(data)) {
    y <- data[1:i]
    if (!anyDuplicated(y)) {
      return(names(y))
    }
  }
  return(character(0))
}

translate_key <- function(data) {
  paste0("PRIMARY KEY (", paste(ps_find_key(data), collapse = ", "), ")")
}

#' Data.frame to sql
#'
#' Draws information from a data.frame to provide code to write an sql table.
#'
#' @param data A data.frame.
#' @param data_name A string of the name of the data.frame.
#' @param table_name A string of the name of the sql table.
#' @return A string.
#' @export
ps_df_to_sql  <- function(data, data_name = deparse(substitute(data)), table_name = tools::toTitleCase(data_name)) {

  check_data(data)
  check_string(data_name)
  check_string(table_name)

  class <- translate_sql(data, translate_class)
  check <- translate_sql(data, translate_checks, collapse = "AND\n")
  key <- translate_key(data)
  unique <- translate_sql(data, translate_unique, collapse = "")
  comment <- paste("\n# ---", table_name, "\n")

  table <- paste0(comment,
                  "DBI::dbGetQuery(conn,\n \"CREATE TABLE ", table_name, " (\n",
                  class, ",\n",
                  "CHECK(\n", check,  "\n),\n",
                  "FOREIGN KEY() REFERENCES ()\n",
                  unique,
                  key, ")\")\n\n",
                  "ps_write_table(", data_name, ", '", table_name, "', ", "conn = conn)\n", collapse = "")
  table
}

#' Create sql database
#'
#' Creates a script to write a sql database from a list of data.frames.
#' Tables are added to the script in the same order as the named list. Foreign keys are not
#'
#' @param x A named list of data.frames.
#' @param db_name A character string of the name of the database.
#' @param load A character string indicating subfolder to load data from.
#' @param path A character string indicating path and file name of the script.
#' @return A R script to create a sql database.
#' @export
ps_create_sql_script <- function(x, db_name = '', load = 'prepare', path = 'create-database.R'){

  check_list(x, named = TRUE)
  lapply(x, check_data)
  check_string(db_name)
  check_string(load)
  check_string(path)

  name <- names(x)
  title <- tools::toTitleCase(name)

  head <- paste0("source('header.R')\n\n",
                 "conn <- open_db('", db_name, "', new = TRUE)\n\n",
                 "set_sub('", load, "')\nload_datas()\n")

  sql <- paste(mapply(function(a, b, c) {ps_df_to_sql(a, data_name = b, table_name = c)},
                      x, name, title), collapse = "")

  write(paste(head, sql), file = path)
}

