is_df <- function(name, envir) {
  is.data.frame(get(name, envir = envir))
}

#' Names Data Frames
#'
#' Gets names of the data frames in by default the calling environment.
#'
#' @param envir The environment to get the names of the data frames for.
#' @return A character vector of the names of the data frames.
ps_names_data <- function(envir = parent.frame()) {
  names <- objects(envir = envir)
  is_df <- vapply(names, is_df, TRUE, envir)
  sort(names[is_df])
}
