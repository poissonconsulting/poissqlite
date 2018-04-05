ask_replace_file <- function(file, ask) {
  if (file.exists(file) && ask && !yesno("Replace file '", file, "'?"))
    return(FALSE)
  TRUE
}

get_units <- function(x) {
  if (is.POSIXct(x)) {
    x %<>% lubridate::tz()
    if (!is_tz(x))
      error("'", x, "' is not an OlsonNames() time zone")
    x %<>% paste("tz:", .)
    stopifnot(is_tz(x))
  } else if (poisspatial::is.sfc(x)) {
    x %<>%
      poisspatial::ps_get_proj4string()
    x %<>% paste("proj:", .)
    stopifnot(poisspatial::is_crs(x))
  } else if (is.ordered(x)) {
    x %<>% levels() %>%
      paste0("'", ., "'") %>%
      paste0(collapse = ", ") %>%
      paste0("c(", ., ")") %>%
      paste("ordered:", .)
    stopifnot(is_ordered(x))
  } else if (is.factor(x)) {
    x %<>% levels() %>%
      paste0("'", ., "'") %>%
      paste0(collapse = ", ") %>%
      paste0("c(", ., ")") %>%
      paste("levels:", .)
    stopifnot(is_levels(x))
  } else if (is.logical(x)) {
    x <- "class: logical"
    stopifnot(is_boolean(x))
  } else if (has_measurement_units(x)) {
    x %<>% deparse_measurement_units()
  } else if (is.Date(x)){
    x <- "class: Date"
    stopifnot(is_date(x))
  } else
    x <- NA_character_
  x
}

set_units <- function(x, units) {
  if (is_tz(units)) {
    if (grepl("^tz:\\s*", units))
      units %<>% sub("^tz:\\s*", "", .)
    x %<>%
      as.POSIXct(tz = "UTC") %>%
      lubridate::force_tz(units)
  } else if (poisspatial::is_crs(units)) {
    if (grepl("^proj:\\s*", units))
      units %<>% sub("^proj:\\s*", "", .)
    x %<>% sf::st_as_sfc()
    x %<>% sf::st_set_crs(units)
  } else if (is_ordered(units)) {
    units %<>% sub("^ordered:\\s*", "", .)
    x %<>% ordered(levels = get_levels(units))
  } else if (is_levels(units)) {
    if(grepl("^levels:\\s*", units))
      units %<>% sub("^levels:\\s*", "", .)
    x %<>% factor(levels = get_levels(units))
  } else if (is_boolean(units)) {
    x %<>% as.logical()
  } else if (is_measurement_units(units)) {
    x %<>% units::set_units(parse_measurement_units(units), mode = "standard")
  } else if (is_date(units)) {
    x %<>% as.Date()
  } else
    stop()
  x
}

has_units <- function(x) {
  is.POSIXct(x) || is.factor(x) || poisspatial::is.sfc(x) || is.logical(x) || has_measurement_units(x) || is.Date(x)
}

is.Date <- function(x) inherits(x, "Date")

is_units <- function(x) is_levels(x) || is_ordered(x) || is_tz(x) || is_crs(x) || is_boolean(x) || is_measurement_units(x) || is_date(x)

is_tz <- function(x) {
  if(grepl("^tz:\\s*", x))
    x %<>% sub("^tz:\\s*", "", .)
  x %in% OlsonNames()
}
is_levels <- function(x) grepl("^c[(]'", x) || grepl("^levels:\\s*c[(]'", x)

is_ordered <- function(x) grepl("^ordered:\\s*c[(]'", x)

is_crs <- function(x) {
  if(grepl("^proj:\\s*", x))
    x %<>% sub("^proj:\\s*", "", .)
  poisspatial::is_crs(x)
}
is_boolean <- function(x) grepl("^class:\\s*logical$", x) || grepl("^logical$", x) || grepl("^c[(]FALSE,TRUE[)]", x)

is_date <- function(x) grepl("^class:\\s*Date$", x) || grepl("^Date$", x)

has_measurement_units <- function(x) inherits(x, "units")

deparse_measurement_units <- function(x)   paste0("unit: ", units::deparse_unit(x))

is_measurement_units <- function(x) grepl("^unit:", x)

parse_measurement_units <- function(x)  {
  x %<>% sub("^unit:\\s*", "", .)
  units::as_units(x)
}

get_levels <- function(x) {
  x %<>%
    parse(text = .) %>%
    eval()
  x
}

is.POSIXct <- function(x) inherits(x, "POSIXct")

is_sqlite_connection <- function(x = getOption("ps.conn")) inherits(x, "SQLiteConnection")

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

  if (!poisutils::ps_create_dir(dir, ask)) error("dir '", dir, "' does not exist")

  if (!ask_replace_file(file, ask))
    error("file '", file, "' already exists")

  if (!dir.exists(dir))
    dir.create(dir, recursive = TRUE)

  writeBin(x, con = file, endian = "little")
}
