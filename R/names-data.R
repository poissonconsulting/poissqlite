#' Names Data Frames
#'
#' Gets names of the data frames in by default the calling environment.
#'
#' @param envir The environment to get the names of the data frames for.
#' @return A character vector of the names of the data frames.
ps_names_data <- function(envir = parent.frame()) {
  .Deprecated("ps_names_datas", package = "poisdata")
  poisdata::ps_names_datas(envir = parent.frame())
}
