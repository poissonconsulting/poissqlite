#' BLOB
#'
#' Converts files in the directory into a named list of BLOBs.
#'
#' For importing into SQLite database it is easiest to convert to a tibble
#' using \code{\link{ps_blob_to_tibble}}.
#'
#' The file extension is stored inside each blob so there is no need to save the filenames.
#'
#' @param dir A string of the directory name.
#' @param pattern A string of the pattern to use when searching for files.
#' @param recursive A flag indicating whether to recurse into subdirectories.
#' @seealso \code{\link{ps_deblob}}, \code{\link{ps_blob_to_tibble}}
#' @export
ps_blob <- function(dir = ".", pattern = "[.]pdf$", recursive = FALSE) {
  check_string(dir)
  check_string(pattern)
  check_flag(recursive)

  if (!dir.exists(dir))
    stop("directory '", dir, "' does not exist", call. = FALSE)

  files <- list.files(dir, pattern = pattern, recursive = recursive, full.names = TRUE)
  sfiles <- list.files(dir, pattern = pattern, recursive = recursive)

  if (!length(files)) stop("there are no files to blob", call. = FALSE)

  blob <- lapply(files, read_file)
  names(blob) <- tools::file_ext(files)

  blob %<>% purrr::lmap(function(x) list(serialize(x, NULL)))

  names(blob) <- sfiles
  blob
}

#' DeBLOB
#'
#' Converts a possibly named list of BLOBs into files in the directory.
#'
#' If x is unnamed the files are assigned the names
#' file1, file2 etc according to their order in x.
#'
#' As the file extension is stored inside each blob the names should not include
#' the file extension. They can removed using \code{\link{file_path_sans_ext}}.
#'
#' @param x A list of BLOBs created by \code{\link{ps_blob}}.
#' @param dir A string of the directory to save the files to.
#' @return An invisible vector of the names of the files saved to dir.
#' @seealso \code{\link{ps_blob}}
#' @export
ps_deblob <- function(x, dir = ".") {
  check_blob(x)
  check_string(dir)

  file <- names(x)

  x %<>%
    lapply(unserialize) %>%
    purrr::flatten()

  if (is.null(file))
    file <- paste0("file", 1:length(x))

  names(x) %<>%
    paste0(file, ".", .) %>%
    file.path(dir, .)

  x %<>% purrr::lmap(function(x, ask = ask) {write_file(unlist(x), names(x)); x})
  invisible(names(x))
}

#' BLOB to tibble
#'
#' @param x A list of blobs
#' @return A tibble with columns File and BLOB.
#' @export
ps_blob_to_tibble <- function(x) {
  check_blob(x)
  if (!length(x)) return(tibble::tibble(File = character(0), BLOB = I(x)))

  if (!is.null(names(x))) {
    names <- names(x)
    names(x) <- NULL
  } else
    names <- paste0("file", 1:length(x))

  tibble::tibble(File = names, BLOB = I(x))
}
