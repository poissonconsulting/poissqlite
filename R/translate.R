library(purrr)
library(lubridate)
df1 <- readRDS('inst/sqldf.rds')
df2 <- df1[1:3]
df3 <- df1[5:9]

is.blob <- function(x) inherits(x, "blob")

get_class <- function(x){
  if(inherits(x, 'Date')) return("TEXT")
  if(inherits(x, 'POSIXct')) return("TEXT")
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

format_sql <- function(data, fun, collapse = ",\n"){
  sql <- mapply(function(x, y) fun(x, y), data, names(data)) %>%
    compact
  if(!length(sql))
    sql <- NULL
  sql %>% paste0(collapse = collapse)
}

get_key <- function(data) {
  for (i in seq_along(data)) {
    y <- data[1:i]
    if (!anyDuplicated(y)) {
      return(paste0("PRIMARY KEY (", paste(names(y), collapse = ", "), ")"))
    }
  }
  return("PRIMARY KEY ()")
}

ps_df_to_sql  <- function(data, data_name = deparse(substitute(data)), table_name = tools::toTitleCase(data_name)) {

  class <- format_sql(data, translate_class)
  check <- format_sql(data, translate_checks, collapse = "AND\n")
  foreign <- "FOREIGN KEY() REFERENCES ()"
  key <- get_key(data)
  unique <- format_sql(data, translate_unique, collapse = "")
  comment <- paste("\n\n# ---", table_name, "\n")

  table <- paste0(comment,
                 "DBI::dbGetQuery(conn,\n \"CREATE TABLE ", table_name, " (\n",
                 class, ",\n",
                 "CHECK(\n", check,  "\n),\n",
                 foreign, ",\n",
                 unique,
                 key, ")\")\n\n",
                 "ps_write_table(", data_name, ", '", table_name, "', ", "conn = conn)\n\n", collapse = "")
  table
}

ps_create_sql_script <- function(x, path = 'create-database.R', db_name = '', load = 'prepare'){

  name <- names(x)
  title <- tools::toTitleCase(name)

  head <- paste0("source('header.R')\n\n",
                 "conn <- open_db('", db_name, "', new = TRUE)\n\n",
                 "set_sub('", load, "')\nload_datas()\n")

  sql <- mapply(function(a, b, c){
    ps_df_to_sql(a, data_name = b, table_name = c)
  }, x, name, title) %>% paste(collapse = "")

  write(paste(head, sql), file = path)
}


