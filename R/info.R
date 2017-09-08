#' Quick dataframe info
#'
#' Returns a list containing information about dataframe columns relevant
#' to SQLite database creation.
#'
#' @param df A data.frame object.
#' @export
ps_df_info <- function(df){
  check_data_frame(df)

  if(inherits(df, "sf")) {
    st_geometry(df) <- NULL
  }
  lapply(df, function(x){
    if(inherits(x, "numeric") || inherits(x, "integer")  || inherits(x, "POSIXct")){
      list(missing = length(which(is.na(x))),
           class = class(x),
           min = min(x, na.rm = T),
           max = max(x, na.rm = T))} else {
             list(missing = length(which(is.na(x))),
                  class = class(x),
                  unique = unique(x))
           }

  })
}
