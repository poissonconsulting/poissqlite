% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metadata.R
\name{ps_update_metadata}
\alias{ps_update_metadata}
\title{Update MetaData Table}
\usage{
ps_update_metadata(conn = getOption("ps.conn"), rm_missing = TRUE)
}
\arguments{
\item{conn}{An SQLiteConnection object.}

\item{rm_missing}{A flag indicating whether to remove rows that no longer correspond to a column in a table.}
}
\value{
An invisible tibble of the new MetaData table.
}
\description{
Updates the MetaData table in an SQLite database.
Creates a new one if absent. The MetaData and Log tables are ignored.
Existing DataUnits and DataDescription values are preserved.
}
