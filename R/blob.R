#' Blob File
#'
#' Converts a file in the directory into a raw object.
#'
#' @param file A string of the file name.
#' @export
ps_blob_file <- function(file) {
  check_string(file)

  blob <- read_bin_file(file) %>%
    list()
  names(blob) <- tools::file_ext(file)

  blob %<>% serialize(NULL)
  blob
}

#' Blob Files
#'
#' Converts files in the directory into a tibble with a column File of file names
#' and a column BLOB of raw objects.
#'
#' @param dir A string of the directory name.
#' @param pattern A string of the pattern to use when searching for files.
#' @param recursive A flag indicating whether to recurse into subdirectories.
#' @export
ps_blob_files <- function(dir = ".", pattern = "[.]pdf$", recursive = FALSE) {
  check_string(dir)
  check_string(pattern)
  check_flag(recursive)

  if (!dir.exists(dir))
    error("directory '", dir, "' does not exist")

  files <- list.files(dir, pattern = pattern, recursive = recursive, full.names = TRUE)
  sfiles <- list.files(dir, pattern = pattern, recursive = recursive)

  if (!length(files)) error("there are no matching files to blob")

  blob <- lapply(files, ps_blob_file)

  tibble::tibble(File = sfiles, BLOB = I(blob))
}

#' Blob Object
#'
#' Converts an R object into a raw object.
#'
#' @param object An R object.
#' @export
ps_blob_object <- function(object) {
  file <-  file.path(tempdir(), "object.rds")
  saveRDS(object, file)
  ps_blob_file(file)
}

#' Deblob to File
#'
#' Converts a raw object back to its original file format.
#'
#' @param blob A raw object.
#' @param file A string of the file (the original file extension is added automatically)
#' @param dir A string of the directory.
#' @param ask A flag indicating whether to ask before creating the directory or replacing a file.
#' @export
ps_deblob_file <- function(blob, file = "blob", dir = ".",
                              ask = getOption("poissqlite.ask", TRUE)) {
  check_blob(blob)
  check_string(file)
  check_string(dir)
  check_flag(ask)

  blob %<>% unserialize()

  file %<>% paste0(".", names(blob))

  blob %<>% unlist()

  write_bin_file(blob, file.path(dir, file), ask)
  invisible(file)
}

#' Deblob to Files
#'
#' Converts a list of raw objects
#' back to their original file formats in the directory.
#'
#' If the elements in \code{blobs} have unique names they are used for the file names,
#' otherwise the files are named file1, file2, ... by order.
#'
#' @param blobs A list of raw objects.
#' @param dir A string of the directory to save the files to.
#' @param ask A flag indicating whether to ask before creating the directory or replacing a file.
#' @export
ps_deblob_files <- function(blobs, dir = ".",
                               ask = getOption("poissqlite.ask", TRUE)) {
  check_string(dir)
  check_flag(ask)

  if (!is.list(blobs)) error("blobs must be a list")
  if (!length(blobs)) error("blobs must not be an empty list")
  if (!all(vapply(blobs, is.raw, TRUE)))
    error("blobs must be a list of raw objects")

  files <- names(blobs)
  names(blobs) <- NULL

  if (is.null(files) || anyDuplicated(files))
    files <- paste0("file", 1:length(blobs))

  files %<>%
    purrr::map2(blobs, ., ps_deblob_file, dir = dir, ask = ask) %>%
    unlist()
  invisible(files)
}

#' Deblob Object
#'
#' Converts a raw object into its original file format
#'  and if it is an .rds file reads it it as an R object. Otherwise it throws an error.
#'
#' @param blob A raw object.
#' @examples
#' mat <- matrix(1:9, nrow = 3)
#' blob <- ps_blob_object(mat)
#' ps_deblob_object(blob)
#' @export
ps_deblob_object <- function(blob) {
  check_blob(blob)

  dir <- tempdir()

  file <- ps_deblob_file(blob, dir = dir, ask = FALSE)

  file %<>% file.path(dir, .)

  if (!grepl("[.]rds$", file))
    error("object blob is not an .rds file")

  readRDS(file)
}
