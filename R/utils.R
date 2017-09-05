ask_create_dir <- function(dir, ask) {
  if (!dir.exists(dir) && ask && !yesno("Create directory '", dir, "'?"))
    return(FALSE)
  TRUE
}

ask_replace_file <- function(file, ask) {
  if (file.exists(file) && ask && !yesno("Replace file '", file, "'?"))
    return(FALSE)
  TRUE
}

error <- function(..., call. = FALSE) {
  stop(..., call. = call.)
}

get_units <- function(x) {
  if (is.POSIXct(x)) {
    x %<>% lubridate::tz()
    if (!is_tz(x))
      error("'", x, "' is not an OlsonNames() time zone")
    return(x)
  }
  NA_character_
}

set_units <- function(x, units) {
  if (is_tz(units)) {
    x %<>% as.POSIXct() %>%
      lubridate::force_tz(units)
    return(x)
  }
  stop()
}

has_units <- function(x) {
  !is.na(get_units(x))
}

is_units <- function(x)  is_tz(x)

is_tz <- function(x) x %in% OlsonNames()

is.POSIXct <- function(x) inherits(x, "POSIXct")

is_sqlite_connection <- function(x) inherits(x, "SQLiteConnection")

is.blob <- function(x) inherits(x, "blob")

read_bin_file <- function(x) {
  if (!file.exists(x))
    error("file '", file, "' does not exist")

  n <- file.info(x)$size
  readBin(x, what = "integer", n = n, endian = "little")
}

warning <- function(..., call. = FALSE) {
  base::warning(..., call. = call.)
}

write_bin_file <- function(x, file, ask) {
  dir <- dirname(file)

  if (!ask_create_dir(dir, ask))
    error("dir '", dir, "' does not exist")

  if (!ask_replace_file(file, ask))
    error("file '", file, "' already exists")

  if (!dir.exists(dir))
    dir.create(dir, recursive = TRUE)

  writeBin(x, con = file, endian = "little")
}
