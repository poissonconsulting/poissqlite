update_names <- function(x, dir) {
  names(x) %<>% file.path(dir, .)
  x
}

read_file <- function(x, n) {
  readBin(x, what = "integer", n = n, endian = "little")
}

write_file <- function(x, con) {
  dir <- dirname(con)

  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  writeBin(x, con = con, endian = "little")
}
