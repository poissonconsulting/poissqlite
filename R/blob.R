#' BLOB
#'
#' Converts files in the directory into a list of BLOBs for storage in an SQLite database.
#'
#'
#' @param dir A string of the directory name.
#' @param pattern A string of the pattern to use when searching for files.
#' @param recursive A flag indicating whether to recurse into subdirectories.
#' @param n An integer of the (maximal) number of records to be read.
#' @return A named list of the BLOBs.
#' @seealso \code{\link{ps_deblob}}
#' @export
ps_blob <- function(dir = ".", pattern = "[.]pdf$", n =  10000L, recursive = TRUE) {
  check_string(dir)
  check_string(pattern)
  check_count(n)
  check_flag(recursive)

  if (!dir.exists(dir))
    stop("directory '", dir, "' does not exist", call. = FALSE)

  files <- list.files(dir, pattern = pattern, recursive = recursive, full.names = TRUE)
  sfiles <- list.files(dir, pattern = pattern, recursive = recursive)

  if (!length(files))
    return(tibble::tibble(File = character(0), BLOB = I(raw(0))))

  blob <- lapply(files, read_file, n = n)
  names(blob) <- tools::file_ext(files)

  blob %<>% purrr::lmap(function(x) list(serialize(x, NULL)))

  names(blob) <- sfiles
  blob
}

#' DeBLOB
#'
#' Converts a possible named list of BLOBs into files in the directory.
#'
#' If x is unnamed the files are assigned the names
#' file1, file2 etc according to their order in x.
#'
#' @param x A list of BLOBs created by \code{\link{ps_blob}}.
#' @param dir A string of the directory to save the files to.
#' @return An invisible vector of the names of the files saved to dir.
#' @seealso \code{\link{ps_deblob}}
#' @export
ps_deblob <- function(x, dir = ".") {
  if (!is.list(x)) stop("x must be list", call. = FALSE)
  if (!length(x)) return(invisible(NULL))
  if (!all(lapply(x, class) == "raw"))
    stop("x must be a list of BLOBs created by ps_blob", call. = FALSE)
  check_unique(names(x))
  check_string(dir)

  file <- names(x)

  x %<>%
    lapply(unserialize) %>%
    purrr::flatten()

  if (is.null(file))
    file <- paste0("file", 1:length(x))

  names(x) %<>% paste0(file, ".", .)

  x %<>% purrr::lmap(function(x, ask = ask) {write_file(unlist(x), names(x)); x})
  invisible(names(x))
}
