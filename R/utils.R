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
  } else if (poisspatial::is.sfc(x)) {
    x %<>%
      poisspatial::ps_get_proj4string()
    stopifnot(poisspatial::is_crs(x))
  } else if (is.factor(x)) {
    x %<>% levels() %>%
      paste0("'", ., "'") %>%
      paste0(collapse = ", ") %>%
      paste0("c(", ., ")")
    stopifnot(is_levels(x))
  } else if (is.logical(x)) {
    x <- "c(FALSE,TRUE)"
    stopifnot(is_boolean(x))
  } else if (has_measurement_units(x)) {
    x %<>% deparse_measurement_units()
  } else
    x <- NA_character_
  x
}

set_units <- function(x, units) {
  if (is_tz(units)) {
    x %<>%
      as.POSIXct() %>%
      lubridate::force_tz(units)
  } else if (poisspatial::is_crs(units)) {
    x %<>% sf::st_as_sfc(crs = units)
  } else if (is_levels(units)) {
    x %<>% factor(levels = get_levels(units))
  } else if (is_boolean(units)) {
    x %<>% as.logical()
  } else if (is_measurement_units(units)) {
    x %<>% units::set_units(parse_measurement_units(units))
  } else
    stop()
  x
}

has_units <- function(x) {
  is.POSIXct(x) || is.factor(x) || poisspatial::is.sfc(x) || is.logical(x) || has_measurement_units(x)
}

is_units <- function(x) is_levels(x) || is_tz(x) || poisspatial::is_crs(x) || is_boolean(x) || is_measurement_units(x)

is_tz <- function(x) x %in% OlsonNames()

is_levels <- function(x) grepl("^c[(]'", x)

is_boolean <- function(x) grepl("^c[(]FALSE,TRUE[)]", x)

has_measurement_units <- function(x) inherits(x, "units")

deparse_measurement_units <- function(x)   paste0("unit: ", units::deparse_unit(x))

is_measurement_units <- function(x) grepl("^unit:", x)

parse_measurement_units <- function(x)  {
  x %<>% sub("^unit:\\s*", "", .)
  units::parse_unit(x)
}

get_levels <- function(x) {
  x %<>%
    parse(text = .) %>%
    eval()
  x
}

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

  if (!poisutils::ps_create_dir(dir, ask)) error("dir '", dir, "' does not exist")

  if (!ask_replace_file(file, ask))
    error("file '", file, "' already exists")

  if (!dir.exists(dir))
    dir.create(dir, recursive = TRUE)

  writeBin(x, con = file, endian = "little")
}
