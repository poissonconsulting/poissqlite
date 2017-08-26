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
