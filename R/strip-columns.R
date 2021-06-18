strip_columns <- function(name, columns, envir) {
  data <- get(name, envir = envir)

  bol <- !colnames(data) %in% columns
  if(all(bol)) return(character(0))
  data %<>% dplyr::select(which(bol))

  assign(name, data, envir = envir)
  name
}

#' Strip Columns
#'
#' Removes columns from all data frames in envir.
#'
#' @param columns A character vector of the columns to remove (if present).
#' @param envir The environment.
#' @return An invisible vector of the modified data frames.
#' @export
ps_strip_columns <- function(columns, envir = parent.frame()) {
  if(!length(columns)) return(invisible(character(0)))

  chk_vector(columns)

  names <- poisdata::ps_names_datas(envir = envir)

  if(!length(data)) return(invisible(character(0)))

  names %<>% purrr::map(strip_columns, columns = columns, envir = envir)
  invisible(unlist(names))
}
