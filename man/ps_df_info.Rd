% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/info.R
\name{ps_df_info}
\alias{ps_df_info}
\title{Quick dataframe info}
\usage{
ps_df_info(df)
}
\arguments{
\item{df}{A data.frame object.}
}
\description{
Returns a list containing information about dataframe columns relevant
to SQLite database creation. If column is numeric, integer or POSIXct,
function returns number of missing values, class, minimum and maximum values.
If column is character, function returns number of missing values, class, and
all unique values.
}
