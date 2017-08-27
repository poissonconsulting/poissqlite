#' Blob File
#'
#' Converts a file in the directory into a blob object.
#'
#' @param file A string of the file name.
#' @export
ps_blob_file <- function(file) {
  check_string(file)

  blob <- read_bin_file(file) %>%
    list()
  names(blob) <- tools::file_ext(file)

  blob %<>%
    serialize(NULL) %>%
    list() %>%
    as.blob()

  names(blob) <- file

  blob
}

#' Blob Files
#'
#' Converts files in the directory into a named vector of blob elements.
#'
#' @param dir A string of the directory name.
#' @param pattern A string of the pattern to use when searching for files.
#' @param recursive A flag indicating whether to recurse into subdirectories.
#' @export
ps_blob_files <- function(dir = ".", pattern = "^[^.].*[.][^.]+$", recursive = FALSE) {
  check_string(dir)
  check_string(pattern)
  check_flag(recursive)

  if (!dir.exists(dir))
    error("directory '", dir, "' does not exist")

  files <- list.files(dir, pattern = pattern, recursive = recursive, full.names = TRUE)
  sfiles <- list.files(dir, pattern = pattern, recursive = recursive, full.names = FALSE)

  dirs <- list.dirs(dir, recursive = recursive, full.names = TRUE)
  is_file <- !files %in% dirs
  files <- files[is_file]
  sfiles <- sfiles[is_file]

  if (!length(files)) error("there are no matching files to blob")

  blobs <- vapply(files, ps_blob_file, as.blob(raw(1))) %>%
    as.blob()

  names(blobs) <- sfiles
  blobs
}

#' Blob Object
#'
#' Converts an R object into a named blob scalar.
#'
#' @param object An R object.
#' @param name A string of the name for the blob.
#' @export
ps_blob_object <- function(object, name = substitute(object)) {
  if (!is.character(name))
    name %<>% deparse()

  check_string(name)

  file <-  file.path(tempdir(), "object.rds")
  saveRDS(object, file)
  blob <- ps_blob_file(file)
  names(blob) <- name
  blob
}

#' Deblob to File
#'
#' Converts a blob object back to its original file format.
#'
#' @param blob A blob object.
#' @param file A string of the file (the original file extension is added automatically)
#' @param dir A string of the directory.
#' @param ask A flag indicating whether to ask before creating the directory or replacing a file.
#' @export
ps_deblob_file <- function(blob, file = "blob", dir = ".",
                              ask = getOption("poissqlite.ask", TRUE)) {

  if (!is.blob(blob) || length(blob) != 1) error("blob must be a blob scalar")

  blob %<>% magrittr::extract2(1L)

  ps_deblob_file_raw(blob, file = file, dir = dir, ask = ask)
}

ps_deblob_file_raw <- function(raw, file = "blob", dir = ".",
                              ask = getOption("poissqlite.ask", TRUE)) {

  stopifnot(is.raw(raw))

  check_string(file)
  check_string(dir)
  check_flag(ask)

  raw %<>% unserialize()

  file %<>% paste0(".", names(raw))

  raw %<>% unlist()

  write_bin_file(raw, file.path(dir, file), ask)
  invisible(file)
}

#' Deblob to Files
#'
#' Converts a possibly uniquely named vector of blob objects
#' back to their original file formats in the directory.
#'
#' @param blobs A vector of blob objects.
#' @param dir A string of the directory to save the files to.
#' @param ask A flag indicating whether to ask before creating the directory or replacing a file.
#' @export
ps_deblob_files <- function(blobs, dir = ".",
                               ask = getOption("poissqlite.ask", TRUE)) {
  if (!is.blob(blobs) || length(blobs) == 0)
    error("blobs must be a non-empty blob vector")
  check_string(dir)
  check_flag(ask)

  files <- names(blobs)

  if (is.null(files)) files <- paste0("file", 1:length(blobs))

  check_unique(files, x_name = "names(blobs)")

  blobs %<>% lapply(identity)

  files %<>%
    purrr::map2(blobs, ., ps_deblob_file_raw, dir = dir, ask = ask) %>%
    unlist()
  invisible(files)
}

#' Deblob Object
#'
#' Converts a blob into an R object. Throws an error if the object was not created using
#' ps_blob_object.
#'
#' @param blob A blob.
#' @examples
#' mat <- matrix(1:9, nrow = 3)
#' blob <- ps_blob_object(mat)
#' ps_deblob_object(blob)
#' @export
ps_deblob_object <- function(blob) {
  if (!is.blob(blob) || length(blob) != 1) error("blob must be a blob scalar")

  dir <- tempdir()

  file <- ps_deblob_file(blob, dir = dir, ask = FALSE)

  file %<>% file.path(dir, .)

  if (!grepl("[.]rds$", file))
    error("object blob is not an .rds file")

  readRDS(file)
}
