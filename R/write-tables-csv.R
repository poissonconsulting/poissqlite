#' Write Tables
#'
#' Writes all the tables in the sqlite database conn to directory dir
#' using \code{write_csv}.
#'
#' @inheritParams ps_load_tables
#' @param dir A string of the directory name.
#' @return An invisible character vector of the data names.
#' @export
ps_write_tables_csvs <- function(conn = getOption("ps.conn"), dir = ".", rename = identity) {

  chk_string(dir)

  ps_load_tables(conn = conn, rename = rename)
  poisdata::ps_write_data_csvs(dir = dir)
}
