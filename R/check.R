check_blob <- function(x) {
  if (!is.list(x)) stop("x must be list", call. = FALSE)
  if (!length(x)) return(x)
  if (!all(lapply(x, class) == "raw"))
    stop("x must be a list of BLOBs created by ps_blob", call. = FALSE)
  check_unique(names(x))
  x
}
