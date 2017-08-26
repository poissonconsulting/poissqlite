library(devtools)
library(knitr)
library(pkgdown)
library(poissqlite)

document()
knit("README.Rmd")

build_site()
